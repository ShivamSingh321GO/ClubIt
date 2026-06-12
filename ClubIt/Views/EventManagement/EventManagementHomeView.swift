import SwiftUI

struct EventManagementHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
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
                
                NavigationLink(destination: ClubItCalendarView(standalone: true)) {
                    Image(systemName: "calendar")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .glassEffect(in: .circle)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding()
            }
            }
        }
    }
}

#Preview {
    EventManagementHomeView()
        .environment(MockData.session(for: .faculty))
}
