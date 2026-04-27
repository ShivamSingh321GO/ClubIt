import Foundation
import Observation
import Supabase

@Observable
final class ClubFileStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var files: [ClubFile] = []
    
    init() {}
    
    @MainActor
    func fetchFiles(clubId: UUID) async throws {
        self.files = try await client
            .from("club_files")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    func addFile(_ file: ClubFile) async throws {
        try await client
            .from("club_files")
            .insert(file)
            .execute()
        
        try await fetchFiles(clubId: file.clubId)
    }
    
    @MainActor
    func deleteFile(_ file: ClubFile) async throws {
        try await client
            .from("club_files")
            .delete()
            .eq("id", value: file.id)
            .execute()
        
        try await fetchFiles(clubId: file.clubId)
    }
}
