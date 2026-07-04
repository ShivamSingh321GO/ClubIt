import SwiftUI
import ClubItShared

struct SubgroupDetailView: View {
    let subgroup: Subgroup
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Use the internal follow button by setting showFollowButton to true
                SubgroupProfileBody(subgroup: subgroup, showExtraSections: false, showFollowButton: true)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SubgroupDetailView(subgroup: MockData.technoJamSubgroup)
            .environment(AppSession())
    }
}
