//
//  UserEncryptionManager.swift
//  ClubItShared
//

import Foundation
import CryptoKit

public final class UserEncryptionManager {
    public static let shared = UserEncryptionManager()
    
    private static let encPrefix = "[ENC]:"
    private static let masterSeedString = "ClubIt.UserDataMasterSecret.v1." + Constants.projectAPIKey
    
    private let masterKey: SymmetricKey
    
    private init() {
        let masterSeedData = Data(UserEncryptionManager.masterSeedString.utf8)
        let hashed = SHA256.hash(data: masterSeedData)
        self.masterKey = SymmetricKey(data: hashed)
    }
    
    // MARK: - Key Derivation per User
    
    /// Derives a unique 256-bit symmetric key for a specific user using CryptoKit HKDF SHA256
    private func deriveKey(for userId: UUID) -> SymmetricKey {
        let salt = userId.uuidString.lowercased().data(using: .utf8) ?? Data()
        let info = "ClubIt.UserEncryption.v1".data(using: .utf8) ?? Data()
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }
    
    // MARK: - Public Encrypt & Decrypt Methods
    
    /// Encrypts sensitive string (e.g. phone number or admission number) into an AES-GCM sealed box, base64 encoded with [ENC]: prefix
    public func encrypt(_ text: String?, for userId: UUID) -> String? {
        guard let text = text, !text.isEmpty else { return text }
        // Avoid double encryption if text is already encrypted
        if isEncrypted(text) { return text }
        
        do {
            let key = deriveKey(for: userId)
            let dataToEncrypt = Data(text.utf8)
            let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
            
            guard let combinedData = sealedBox.combined else {
                return text
            }
            
            return UserEncryptionManager.encPrefix + combinedData.base64EncodedString()
        } catch {
            print("DEBUG ERROR: [UserEncryptionManager] Encryption failed for user \(userId): \(error)")
            return text
        }
    }
    
    /// Decrypts encrypted string if it starts with [ENC]:, otherwise returns the string as-is for backward compatibility
    public func decrypt(_ text: String?, for userId: UUID) -> String? {
        guard let text = text, !text.isEmpty else { return text }
        guard text.hasPrefix(UserEncryptionManager.encPrefix) else {
            return text // Legacy/unencrypted plaintext
        }
        
        let rawBase64 = String(text.dropFirst(UserEncryptionManager.encPrefix.count))
        let base64Part = rawBase64.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let combinedData = Data(base64Encoded: base64Part) else {
            print("DEBUG ERROR: [UserEncryptionManager] Invalid Base64 ciphertext for user \(userId)")
            return text
        }
        
        do {
            let key = deriveKey(for: userId)
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            if let decryptedString = String(data: decryptedData, encoding: .utf8) {
                return decryptedString
            } else {
                return text
            }
        } catch {
            print("DEBUG ERROR: [UserEncryptionManager] Decryption failed for user \(userId): \(error)")
            return text
        }
    }
    
    public func isEncrypted(_ text: String) -> Bool {
        return text.hasPrefix(UserEncryptionManager.encPrefix)
    }
}
