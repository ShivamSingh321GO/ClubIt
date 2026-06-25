import SwiftUI
import ClubItShared

struct ClubDetailView: View {
    let club: Club
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Use the internal follow button by setting showFollowButton to true
                ClubProfileBody(club: club, showExtraSections: false, showFollowButton: true)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ClubDetailView(club: MockData.technoJamClub)
            .environment(AppSession())
    }
}
