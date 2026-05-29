import SwiftUI

struct VicePresidentHomeView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedEventId: UUID? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    if let user = appSession.currentUser {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // Tasks Section
                            HStack {
                                Text("Tasks")
                                NavigationLink(destination: TasksListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeTasksModule(user: user)
                            
                            // Approval Requests Section
                            HStack {
                                Text("Approval Requests")
                                NavigationLink(destination: VPApprovalsListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            VicePresidentApprovalsModule(user: user) { id in
                                selectedEventId = id
                            }
                            
                            ClubItCalendarView()
                                .padding(.top, 8)
                        }
                        .padding(.horizontal)
                        .navigationTitle("Home")
                        .toolbarTitleDisplayMode(.inlineLarge)
                        .navigationDestination(item: $selectedEventId) { id in
                            if let club = appSession.clubStore.allClubs.first(where: { $0.vicePresidentId == user.id }),
                               let event = appSession.eventStore.events.first(where: { $0.id == id }) {
                                EventManagementApprovalDetailView(club: club, event: event)
                            }
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

// MARK: - VicePresidentApprovalsModule
struct VicePresidentApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    let onSelect: (UUID) -> Void

    var body: some View {
        let pendingApprovals = appSession.approvalStore.approvals.filter { approval in
            approval.receiverId == user.id &&
            approval.type == .event &&
            approval.status == .pending &&
            appSession.eventStore.events.contains(where: { $0.id == approval.eventId })
        }.sorted(by: { $0.createdAt > $1.createdAt })
        
        VStack(alignment: .leading, spacing: 16) {
            if pendingApprovals.isEmpty {
                Text("No pending approvals")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(pendingApprovals.prefix(2)) { approval in
                        if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }),
                           let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                            NavigationLink(destination: EventManagementApprovalDetailView(club: club, event: event)) {
                                VPApprovalEventCard(event: event, approval: approval, club: club)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - VPApprovalEventCard
struct VPApprovalEventCard: View {
    let event: Event
    let approval: Approval
    let club: Club

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 48, height: 48)
                Text(String(club.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                Text("Draft approval requested")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

// MARK: - VPApprovalsListView
struct VPApprovalsListView: View {
    @Environment(AppSession.self) var appSession
    let user: User

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                let approvals = appSession.approvalStore.approvals.filter { approval in
                    approval.receiverId == user.id &&
                    approval.type == .event &&
                    appSession.eventStore.events.contains(where: { $0.id == approval.eventId })
                }.sorted(by: { $0.createdAt > $1.createdAt })

                if approvals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No approvals history found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(approvals) { approval in
                            if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }),
                               let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                                NavigationLink(destination: EventManagementApprovalDetailView(club: club, event: event)) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.1))
                                                .frame(width: 48, height: 48)
                                            Text(String(club.name.prefix(1)))
                                                .font(.headline)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.name)
                                                .font(.headline)
                                            Text("Submitted on \(event.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(approval.status.rawValue.capitalized)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(approval.status == .approved ? Color.green.opacity(0.1) : (approval.status == .rejected ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)))
                                            .foregroundColor(approval.status == .approved ? .green : (approval.status == .rejected ? .red : .orange))
                                            .clipShape(Capsule())
                                    }
                                    .padding()
                                    .glassEffect(in: .rect(cornerRadius: 24))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Draft Approvals")
        .navigationBarTitleDisplayMode(.inline)
    }
}
