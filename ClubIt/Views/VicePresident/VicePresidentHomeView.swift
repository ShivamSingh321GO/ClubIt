import SwiftUI

struct VicePresidentHomeView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedEventId: UUID? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
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
                } // Close inner ZStack
                
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
        }.sorted(by: { a1, a2 in
            guard let e1 = appSession.eventStore.events.first(where: { $0.id == a1.eventId }),
                  let e2 = appSession.eventStore.events.first(where: { $0.id == a2.eventId }) else { return false }
            if Calendar.current.isDate(e1.startDate, inSameDayAs: e2.startDate) {
                return (e1.startTime ?? Date.distantFuture) < (e2.startTime ?? Date.distantFuture)
            }
            return e1.startDate < e2.startDate
        })
        
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
                HStack(spacing: 8) {
                    EventDateTag(dateString: event.dateRangeString)
                }
                .padding(.bottom, 2)
                
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
    @State private var selectedFilter: ApprovalFilter = .all

    enum ApprovalFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
    }

    private func count(for filter: ApprovalFilter, approvals: [Approval]) -> Int {
        if filter == .all {
            return approvals.count
        }
        return approvals.filter { approval in
            switch filter {
            case .pending: return approval.status == .pending
            case .approved: return approval.status == .approved
            case .rejected: return approval.status == .rejected
            default: return false
            }
        }.count
    }

    var body: some View {
        let approvals = appSession.approvalStore.approvals.filter { approval in
            approval.receiverId == user.id &&
            approval.type == .event &&
            appSession.eventStore.events.contains(where: { $0.id == approval.eventId })
        }.sorted(by: { a1, a2 in
            guard let e1 = appSession.eventStore.events.first(where: { $0.id == a1.eventId }),
                  let e2 = appSession.eventStore.events.first(where: { $0.id == a2.eventId }) else { return false }
            if Calendar.current.isDate(e1.startDate, inSameDayAs: e2.startDate) {
                return (e1.startTime ?? Date.distantFuture) < (e2.startTime ?? Date.distantFuture)
            }
            return e1.startDate < e2.startDate
        })

        let filteredApprovals = approvals.filter { approval in
            if selectedFilter == .all {
                return true
            }
            switch selectedFilter {
            case .pending: return approval.status == .pending
            case .approved: return approval.status == .approved
            case .rejected: return approval.status == .rejected
            default: return false
            }
        }

        VStack(spacing: 0) {
            if !approvals.isEmpty {
                // Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ApprovalFilter.allCases, id: \.self) { filter in
                            VPFilterPill(
                                title: "\(filter.rawValue) \(count(for: filter, approvals: approvals))",
                                isSelected: selectedFilter == filter,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
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
                    } else if filteredApprovals.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: selectedFilter == .pending ? "hourglass" : (selectedFilter == .approved ? "checkmark.circle" : "xmark.circle"))
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No \(selectedFilter.rawValue) approvals found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredApprovals) { approval in
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
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
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
        }
        .navigationTitle("Draft Approvals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - VPFilterPill Subcomponent
fileprivate struct VPFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accent : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
