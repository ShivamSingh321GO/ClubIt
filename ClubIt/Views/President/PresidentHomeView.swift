import SwiftUI
import ClubItShared

struct PresidentHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        if let user = appSession.currentUser {
                            VStack(alignment: .leading, spacing: 28) {
                                
                                // Today's Tasks Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("All Tasks")
                                        NavigationLink(destination: TasksListView(user: user)) {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                    .font(.title2)
                                    .bold()
                                    
                                    HomeTasksModule(user: user)
                                }
                                
                                // Approval Management Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Approval Management")
                                        NavigationLink(destination: EventManagementApprovalSubgroupsView()) {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                    .font(.title2)
                                    .bold()
                                    
                                    PresidentApprovalsModule(user: user)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable {
                        await appSession.refreshData()
                    }
                }
                .background(Color(.systemBackground))
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
                
                if appSession.isRefreshing && appSession.eventStore.events.isEmpty {
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
                
                NavigationLink(destination: ClubItCalendarView(standalone: true)) {
                    Image(systemName: "calendar")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .glassEffect(in: .circle)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding()
            } // Close ZStack
        }
        .task {
            await appSession.refreshData()
        }
        .sheet(item: Bindable(appSession).selectedTask) { task in
            TaskDetailView(task: task)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    let session = MockData.session(for: .groupLead)
    PresidentHomeView()
        .environment(session)
}
