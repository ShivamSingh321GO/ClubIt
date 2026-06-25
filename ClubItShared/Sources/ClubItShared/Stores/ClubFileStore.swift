import Foundation
import Observation
import Supabase

@Observable
public final class ClubFileStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var files: [ClubFile] = []
    
    public init() {}
    
    @MainActor
    public func fetchFiles(clubId: UUID) async throws {
        self.files = try await client
            .from("club_files")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    public func addFile(_ file: ClubFile, fileData: Data) async throws {
        // 1. Upload file data to Supabase Storage
        let publicUrl = try await ImageUploadService.shared.uploadClubFile(
            fileData: fileData,
            fileName: file.name,
            clubId: file.clubId,
            fileId: file.id
        )
        
        // 2. Set the public file URL on the metadata record
        var updatedFile = file
        updatedFile.fileURL = publicUrl
        
        // 3. Insert metadata record in the database
        try await client
            .from("club_files")
            .insert(updatedFile)
            .execute()
        
        try await fetchFiles(clubId: file.clubId)
    }
    
    @MainActor
    public func deleteFile(_ file: ClubFile) async throws {
        // 1. Delete record from Supabase database
        try await client
            .from("club_files")
            .delete()
            .eq("id", value: file.id)
            .execute()
        
        // 2. Delete file from Supabase storage bucket if URL exists
        if let fileUrlString = file.fileURL, let url = URL(string: fileUrlString) {
            let storagePath = "\(file.clubId.uuidString)/\(url.lastPathComponent)"
            try? await client.storage
                .from("club-files")
                .remove(paths: [storagePath])
        }
        
        try await fetchFiles(clubId: file.clubId)
    }
}
