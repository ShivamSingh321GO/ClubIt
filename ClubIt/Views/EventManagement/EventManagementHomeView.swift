import SwiftUI

struct EventManagementHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Approval Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Approval Management")
                                NavigationLink(destination: EventManagementApprovalClubsView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            if user.role == .faculty {
                                FacultyApprovalsModule(user: user)
                            } else {
                                PresidentApprovalsModule(user: user)
                            }
                        }
                        
                        // Venue Allocation Overview Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Allocated Venues")
                                NavigationLink(destination: FacultyVenueListView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeVenuesModule()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            NavigationLink {
                                LeadNotificationView()
                            } label: {
                                Image(systemName: "bell")
                            }
                            
                            NavigationLink {
                                LeadProfileView()
                            } label: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    EventManagementHomeView()
        .environment(MockData.session(for: .faculty))
}
