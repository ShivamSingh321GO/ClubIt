import Foundation
import CryptoKit

public final class ChatEncryptionManager {
    public static let shared = ChatEncryptionManager()
    
    private static let encPrefix = "[ENC]:"
    private static let masterSeedString = "ClubIt.AppSharedMasterSecret.v1." + Constants.projectAPIKey
    
    private let masterKey: SymmetricKey
    
    private init() {
        let masterSeedData = Data(ChatEncryptionManager.masterSeedString.utf8)
        let hashed = SHA256.hash(data: masterSeedData)
        self.masterKey = SymmetricKey(data: hashed)
    }
    
    // MARK: - Key Derivation per Chat
    
    /// Derives a unique, deterministic 256-bit symmetric key for a specific chatId using CryptoKit HKDF SHA256
    private func deriveKey(for chatId: UUID) -> SymmetricKey {
        let salt = chatId.uuidString.lowercased().data(using: .utf8) ?? Data()
        let info = "ClubIt.ChatEncryption.v1".data(using: .utf8) ?? Data()
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }
    
    // MARK: - Public Encrypt & Decrypt Methods
    
    /// Encrypts plaintext string into an AES-GCM sealed box, base64 encoded with [ENC]: prefix
    public func encrypt(_ text: String, for chatId: UUID) -> String {
        guard !text.isEmpty else { return text }
        
        do {
            let key = deriveKey(for: chatId)
            let dataToEncrypt = Data(text.utf8)
            let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
            
            guard let combinedData = sealedBox.combined else {
                return text
            }
            
            return ChatEncryptionManager.encPrefix + combinedData.base64EncodedString()
        } catch {
            print("DEBUG ERROR: [ChatEncryptionManager] Encryption failed for chat \(chatId): \(error)")
            return text
        }
    }
    
    /// Decrypts a message if it starts with [ENC]:, otherwise returns the string as-is for backward compatibility
    public func decrypt(_ text: String, for chatId: UUID) -> String {
        guard text.hasPrefix(ChatEncryptionManager.encPrefix) else {
            return text // Legacy/unencrypted message or non-encrypted string
        }
        
        let rawBase64 = String(text.dropFirst(ChatEncryptionManager.encPrefix.count))
        let base64Part = rawBase64.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let combinedData = Data(base64Encoded: base64Part) else {
            print("DEBUG ERROR: [ChatEncryptionManager] Invalid Base64 ciphertext for chat \(chatId)")
            return text
        }
        
        do {
            let key = deriveKey(for: chatId)
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            if let decryptedString = String(data: decryptedData, encoding: .utf8) {
                return decryptedString
            } else {
                return text
            }
        } catch {
            print("DEBUG ERROR: [ChatEncryptionManager] Decryption failed for chat \(chatId): \(error)")
            return text
        }
    }
    
    public func isEncrypted(_ text: String) -> Bool {
        return text.hasPrefix(ChatEncryptionManager.encPrefix)
    }
}
