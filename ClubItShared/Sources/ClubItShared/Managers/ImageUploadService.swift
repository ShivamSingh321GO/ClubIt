//
//  ImageUploadService.swift
//  ClubIt
//
//  Created by Antigravity on 6/10/26.
//

import Foundation
import Supabase

public final class ImageUploadService {
    public static let shared = ImageUploadService()
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let bucketName = "event-images"
    
    private init() {}
    
    /// Uploads image data to Supabase Storage and returns the public URL string.
    /// - Parameters:
    ///   - imageData: The raw image Data to upload
    ///   - eventId: The event UUID, used to create a unique file path
    /// - Returns: The public URL string for the uploaded image
    public func uploadEventBanner(imageData: Data, eventId: UUID) async throws -> String {
        let fileName = "\(eventId.uuidString)/banner.jpg"
        
        // Upload to Supabase Storage
        try await client.storage
            .from(bucketName)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        // Get the public URL
        let publicURL = try client.storage
            .from(bucketName)
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Uploads image data to Supabase Storage in the club-images bucket and returns the public URL string.
    /// - Parameters:
    ///   - imageData: The raw image Data to upload
    ///   - clubId: The club UUID, used as the folder name
    ///   - imageId: The image UUID, used as the file name
    /// - Returns: The public URL string for the uploaded image
    public func uploadClubImage(imageData: Data, clubId: UUID, imageId: UUID) async throws -> String {
        let clubBucket = "club-images"
        let fileName = "\(clubId.uuidString)/\(imageId.uuidString).jpg"
        
        // Upload to Supabase Storage
        try await client.storage
            .from(clubBucket)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        // Get the public URL
        let publicURL = try client.storage
            .from(clubBucket)
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Uploads file data to Supabase Storage in the club-files bucket and returns the public URL string.
    /// - Parameters:
    ///   - fileData: The raw file Data to upload
    ///   - fileName: The original name of the file
    ///   - clubId: The club UUID, used as the folder name
    ///   - fileId: The file UUID, used as part of the unique path
    /// - Returns: The public URL string for the uploaded file
    public func uploadClubFile(fileData: Data, fileName: String, clubId: UUID, fileId: UUID) async throws -> String {
        let fileBucket = "club-files"
        // Sanitize the fileName to prevent storage path issues, but keep extension
        let sanitizedName = fileName.components(separatedBy: CharacterSet.alphanumerics.inverted.union(CharacterSet(charactersIn: "."))).joined(separator: "_")
        let storagePath = "\(clubId.uuidString)/\(fileId.uuidString)_\(sanitizedName)"
        
        // Upload to Supabase Storage
        try await client.storage
            .from(fileBucket)
            .upload(
                storagePath,
                data: fileData,
                options: FileOptions(
                    contentType: "application/octet-stream",
                    upsert: true
                )
            )
        
        // Get the public URL
        let publicURL = try client.storage
            .from(fileBucket)
            .getPublicURL(path: storagePath)
        
        return publicURL.absoluteString
    }
}

