//
//  TasksListView.swift
//  ClubIt
//
//
//
//

import SwiftUI

struct TasksListView: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    @State private var selectedFilter: TaskFilter = .showAll
    @State private var showingAddTaskForm = false
    @State private var taskToEdit: Tasks?
    
    enum TaskFilter: String, CaseIterable {
        case showAll = "All"
        case showPending = "Pending"
        case showCompleted = "Completed"
    }
    
    var filteredTasks: [Tasks] {
        switch selectedFilter {
        case .showAll:
            return appSession.taskStore.filteredTasks(for: user.id)
        case .showPending:
            return appSession.taskStore.filteredPendingTasks(for: user.id)
        case .showCompleted:
            return appSession.taskStore.filteredCompletedTasks(for: user.id)
        }
    }
    
    func count(for filter: TaskFilter) -> Int {
        switch filter {
        case .showAll: return appSession.taskStore.filteredTasks(for: user.id).count
        case .showPending: return appSession.taskStore.filteredPendingTasks(for: user.id).count
        case .showCompleted: return appSession.taskStore.filteredCompletedTasks(for: user.id).count
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: "\(filter.rawValue) (\(count(for: filter)))",
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    
                    // Tasks List
                    if filteredTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("No tasks found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { (index, task) in
                                    TaskRowView(task: task, now: appSession.currentTime)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .refreshable {
                            await appSession.refreshData()
                        }
                    }
                }
                
                if appSession.isRefreshing {
                    VStack {
                        ProgressView()
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        Text("Updating tasks...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                    .transition(.opacity)
                }
            }
            .toolbar {
                if appSession.currentRole ?? .clubMember == .clubLead || appSession.currentRole ?? .clubMember == .president {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddTaskForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTaskForm) {
                AddTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(initialTask: task)
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: Bindable(appSession).selectedTask) { task in
                TaskDetailView(task: task)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Subcomponents
struct FilterPill: View {
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

#Preview {
    let session = AppSession()
    session.currentRole = .clubLead
    return TasksListView(user: MockData.clubLeadUser)
        .environment(session)
}
