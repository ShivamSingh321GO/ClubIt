import SwiftUI

struct HomeTasksModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    @State private var taskToEdit: Tasks?
    
    var recentTasks: [Tasks] {
        Array(appSession.taskStore.filteredPendingTasks(for: user.id).prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(recentTasks.enumerated()), id: \.element.id) { index, task in
                TaskRowView(task: task, now: appSession.currentTime)
            }
        }
        .sheet(item: $taskToEdit) { task in
            AddTaskView(initialTask: task)
        }
    }
}

#Preview {
    let session = AppSession()
    session.currentUser = MockData.clubLeadUser
    
    return NavigationStack {
        HomeTasksModule(user: MockData.clubLeadUser)
            .environment(session)
    }
}
