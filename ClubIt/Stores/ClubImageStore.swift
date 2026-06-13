import Foundation
import Observation
import Supabase

struct ClubImageSection: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var images: [ClubImage]
    var remainingCount: Int
}

@Observable
final class ClubImageStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var sections: [ClubImageSection] = []
    
    init(clubId: UUID? = nil) {
        // Fallback placeholder during init
        self.sections = []
    }
    
    @MainActor
    func fetchImages(clubId: UUID) async throws {
        // Fetch all images for the current club sorted by creation date
        let dbImages: [ClubImage] = try await client
            .from("club_images")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Group the images by their section title
        let grouped = Dictionary(grouping: dbImages, by: { $0.title })
        
        // Map the grouped dictionary to ClubImageSection and sort by latest image date
        self.sections = grouped.map { title, images in
            ClubImageSection(
                title: title,
                images: images,
                remainingCount: max(0, images.count - 6)
            )
        }.sorted { s1, s2 in
            let date1 = s1.images.first?.createdAt ?? Date.distantPast
            let date2 = s2.images.first?.createdAt ?? Date.distantPast
            return date1 > date2
        }
        
        print("DEBUG: Fetched \(dbImages.count) images grouped into \(sections.count) sections")
        
        // Pre-cache all remote images in background for instant display
        let remoteUrls = dbImages
            .map(\.fileUrl)
            .filter { $0.hasPrefix("http://") || $0.hasPrefix("https://") }
        ImageCacheManager.shared.prefetch(urls: remoteUrls)
    }
    
    @MainActor
    func addImage(title: String, imageData: Data, clubId: UUID, uploadedBy: UUID) async throws {
        let imageId = UUID()
        
        // 1. Upload to Supabase Storage Bucket
        let publicUrl = try await ImageUploadService.shared.uploadClubImage(
            imageData: imageData,
            clubId: clubId,
            imageId: imageId
        )
        
        // 2. Save metadata to public.club_images table
        let newImage = ClubImage(
            id: imageId,
            clubId: clubId,
            eventId: nil,
            type: .image,
            title: title,
            fileUrl: publicUrl,
            uploadedBy: uploadedBy,
            createdAt: Date()
        )
        
        try await client
            .from("club_images")
            .insert(newImage)
            .execute()
        
        // 3. Refresh our local sections list
        try await fetchImages(clubId: clubId)
    }
    
    @MainActor
    func addSection(_ section: ClubImageSection) {
        // Keeps local compatibility interface if needed
        sections.insert(section, at: 0)
    }
    
    @MainActor
    func addImageToSection(sectionId: UUID, image: ClubImage) {
        if let index = sections.firstIndex(where: { $0.id == sectionId }) {
            sections[index].images.insert(image, at: 0)
            sections[index].remainingCount = max(0, sections[index].images.count - 6)
        }
    }
    
    @MainActor
    func deleteImage(_ image: ClubImage) async throws {
        // 1. Delete record from Supabase database
        try await client
            .from("club_images")
            .delete()
            .eq("id", value: image.id)
            .execute()
        
        // 2. Delete file from Supabase storage bucket
        let storagePath = "\(image.clubId.uuidString)/\(image.id.uuidString).jpg"
        try? await client.storage
            .from("club-images")
            .remove(paths: [storagePath])
        
        // 3. Refresh database state
        try await fetchImages(clubId: image.clubId)
    }
    
    @MainActor
    func deleteImageOptimistically(_ image: ClubImage) {
        for i in 0..<sections.count {
            if let index = sections[i].images.firstIndex(where: { $0.id == image.id }) {
                sections[i].images.remove(at: index)
                sections[i].remainingCount = max(0, sections[i].images.count - 6)
                break
            }
        }
        sections.removeAll(where: { $0.images.isEmpty })
    }
}
