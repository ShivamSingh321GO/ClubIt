import Foundation
import Observation
import Supabase

@Observable
public final class SubgroupFileStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var files: [SubgroupFile] = []
    
    public init() {}
    
    @MainActor
    public func fetchFiles(subgroupId: UUID) async throws {
        self.files = try await client
            .from("subgroup_files")
            .select()
            .eq("subgroup_id", value: subgroupId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    public func addFile(_ file: SubgroupFile, fileData: Data) async throws {
        // 1. Upload file data to Supabase Storage
        let publicUrl = try await ImageUploadService.shared.uploadSubgroupFile(
            fileData: fileData,
            fileName: file.name,
            subgroupId: file.subgroupId,
            fileId: file.id
        )
        
        // 2. Set the public file URL on the metadata record
        var updatedFile = file
        updatedFile.fileURL = publicUrl
        
        // 3. Insert metadata record in the database
        try await client
            .from("subgroup_files")
            .insert(updatedFile)
            .execute()
        
        try await fetchFiles(subgroupId: file.subgroupId)
    }
    
    @MainActor
    public func deleteFile(_ file: SubgroupFile) async throws {
        // 1. Delete record from Supabase database
        try await client
            .from("subgroup_files")
            .delete()
            .eq("id", value: file.id)
            .execute()
        
        // 2. Delete file from Supabase storage bucket if URL exists
        if let fileUrlString = file.fileURL, let url = URL(string: fileUrlString) {
            let storagePath = "\(file.subgroupId.uuidString)/\(url.lastPathComponent)"
            try? await client.storage
                .from("subgroup-files")
                .remove(paths: [storagePath])
        }
        
        try await fetchFiles(subgroupId: file.subgroupId)
    }
}
