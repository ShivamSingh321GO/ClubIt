import Foundation
import Observation
import Supabase

public struct SubgroupImageSection: Identifiable, Hashable {
    public var id = UUID()
    public var title: String
    public var images: [SubgroupImage]
    public var remainingCount: Int

    public init(id: UUID = UUID(), title: String, images: [SubgroupImage], remainingCount: Int) {
        self.id = id
        self.title = title
        self.images = images
        self.remainingCount = remainingCount
    }
}

@Observable
public final class SubgroupImageStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var sections: [SubgroupImageSection] = []
    
    public init(subgroupId: UUID? = nil) {
        // Fallback placeholder during init
        self.sections = []
    }
    
    @MainActor
    public func fetchImages(subgroupId: UUID) async throws {
        // Fetch all images for the current subgroup sorted by creation date
        let dbImages: [SubgroupImage] = try await client
            .from("subgroup_images")
            .select()
            .eq("subgroup_id", value: subgroupId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Group the images by their section title
        let grouped = Dictionary(grouping: dbImages, by: { $0.title })
        
        // Map the grouped dictionary to SubgroupImageSection and sort by latest image date
        self.sections = grouped.map { title, images in
            SubgroupImageSection(
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
        #if canImport(UIKit)
        ImageCacheManager.shared.prefetch(urls: remoteUrls)
        #endif
    }
    
    @MainActor
    public func addImage(title: String, imageData: Data, subgroupId: UUID, uploadedBy: UUID) async throws {
        let imageId = UUID()
        
        // 1. Upload to Supabase Storage Bucket
        let publicUrl = try await ImageUploadService.shared.uploadSubgroupImage(
            imageData: imageData,
            subgroupId: subgroupId,
            imageId: imageId
        )
        
        // 2. Save metadata to public.subgroup_images table
        let newImage = SubgroupImage(
            id: imageId,
            subgroupId: subgroupId,
            eventId: nil,
            type: .image,
            title: title,
            fileUrl: publicUrl,
            uploadedBy: uploadedBy,
            createdAt: Date()
        )
        
        try await client
            .from("subgroup_images")
            .insert(newImage)
            .execute()
        
        // 3. Refresh our local sections list
        try await fetchImages(subgroupId: subgroupId)
    }
    
    @MainActor
    public func addSection(_ section: SubgroupImageSection) {
        // Keeps local compatibility interface if needed
        sections.insert(section, at: 0)
    }
    
    @MainActor
    public func addImageToSection(sectionId: UUID, image: SubgroupImage) {
        if let index = sections.firstIndex(where: { $0.id == sectionId }) {
            sections[index].images.insert(image, at: 0)
            sections[index].remainingCount = max(0, sections[index].images.count - 6)
        }
    }
    
    @MainActor
    public func deleteImage(_ image: SubgroupImage) async throws {
        // 1. Delete record from Supabase database
        try await client
            .from("subgroup_images")
            .delete()
            .eq("id", value: image.id)
            .execute()
        
        // 2. Delete file from Supabase storage bucket
        let storagePath = "\(image.subgroupId.uuidString)/\(image.id.uuidString).jpg"
        try? await client.storage
            .from("subgroup-images")
            .remove(paths: [storagePath])
        
        // 3. Refresh database state
        try await fetchImages(subgroupId: image.subgroupId)
    }
    
    @MainActor
    public func deleteImageOptimistically(_ image: SubgroupImage) {
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
