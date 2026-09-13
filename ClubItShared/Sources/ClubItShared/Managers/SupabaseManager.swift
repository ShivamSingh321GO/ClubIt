import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()
    
    public let client: SupabaseClient
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: Constants.projectURLString)!,
            supabaseKey: Constants.projectAPIKey,
            options: SupabaseClientOptions(
                global: .init(session: session)
            )
        )
    }
}
