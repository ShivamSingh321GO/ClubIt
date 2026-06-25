import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()
    
    public let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Constants.projectURLString)!,
            supabaseKey: Constants.projectAPIKey
        )
    }
}
