import SwiftUI

struct LeadHomeView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedEventId: UUID? = nil

    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    if let user = appSession.currentUser {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text("Tasks")
                                NavigationLink(destination: TasksListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeTasksModule(user: user)
                            
                            HStack {
                                Text("Approval Requests")
                                NavigationLink(destination: ApprovalsListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeApprovalsModule(user: user) { id in
                                selectedEventId = id
                            }
                            
                            ClubItCalendarView()
                                .padding(.top, 8)
                        }
                        .padding(.horizontal)
                        .navigationTitle("Home")
                        .toolbarTitleDisplayMode(.inlineLarge)
                        .navigationDestination(item: $selectedEventId) { id in
                            LeadEventApprovalDetailView(eventId: id)
                        }
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
                .refreshable {
                    await appSession.refreshData()
                }
                
                if appSession.isRefreshing {
                    VStack {
                        ProgressView()
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        Text("Loading data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                    .transition(.opacity)
                }
            }
        }
        .sheet(item: Bindable(appSession).selectedTask) { task in
            TaskDetailView(task: task)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}

// MARK: - Modules
struct HomeApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    let onSelect: (UUID) -> Void

    
    var body: some View {
        let sentApprovals = appSession.approvalStore.approvals.filter { approval in
            approval.senderId == user.id &&
            approval.type == .event &&
            appSession.eventStore.events.contains(where: { $0.id == approval.eventId })
        }.sorted(by: { $0.createdAt > $1.createdAt })
        
        VStack(alignment: .leading, spacing: 16) {
            if sentApprovals.isEmpty {
                Text("No recent approval requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(sentApprovals.prefix(2)) { approval in
                        if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                            NavigationLink(destination: LeadEventApprovalDetailView(eventId: event.id)) {
                                LeadApprovalEventCard(event: event, approval: approval)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}





#Preview {
    let session = AppSession()
    session.currentUser = MockData.clubLeadUser
    
    return LeadHomeView()
        .environment(session)
}
