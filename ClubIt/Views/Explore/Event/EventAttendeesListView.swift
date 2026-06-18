import SwiftUI

struct EventAttendeesListView: View {
    @Environment(AppSession.self) private var appSession
    let event: Event
    
    var body: some View {
        List {
            if appSession.attendanceStore.isFetching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if appSession.attendanceStore.eventAttendances.isEmpty {
                Text("No attendees have scanned yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(appSession.attendanceStore.eventAttendances) { attendance in
                    let user = appSession.clubStore.allUsers.first(where: { $0.id == attendance.userId })
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user?.name ?? "Unknown User")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Entry")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let entryTime = attendance.entryTime {
                                    Text(entryTime, style: .time)
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                } else {
                                    Text("-")
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Exit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let exitTime = attendance.exitTime {
                                    Text(exitTime, style: .time)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                } else {
                                    Text("-")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Attendees")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await appSession.attendanceStore.fetchAttendance(for: event.id)
            }
        }
        .refreshable {
            await appSession.attendanceStore.fetchAttendance(for: event.id)
        }
    }
}
