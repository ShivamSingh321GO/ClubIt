//
//  ImageUploadService.swift
//  ClubIt
//
//  Created by Antigravity on 6/10/26.
//

import Foundation
import Supabase

final class ImageUploadService {
    static let shared = ImageUploadService()
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let bucketName = "event-images"
    
    private init() {}
    
    /// Uploads image data to Supabase Storage and returns the public URL string.
    /// - Parameters:
    ///   - imageData: The raw image Data to upload
    ///   - eventId: The event UUID, used to create a unique file path
    /// - Returns: The public URL string for the uploaded image
    func uploadEventBanner(imageData: Data, eventId: UUID) async throws -> String {
        let fileName = "\(eventId.uuidString)/banner.jpg"
        
        // Upload to Supabase Storage
        try await client.storage
            .from(bucketName)
            .upload(
                path: fileName,
                file: imageData,
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
}
