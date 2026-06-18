import SwiftUI

struct EventAttendeesListView: View {
    @Environment(AppSession.self) private var appSession
    let event: Event
    
    @State private var isExporting = false
    @State private var exportFileURL: URL?
    
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
                    
                    if let validUser = user {
                        NavigationLink(destination: destinationProfile(for: validUser)) {
                            attendanceRow(user: validUser, attendance: attendance)
                        }
                    } else {
                        attendanceRow(user: nil, attendance: attendance)
                    }
                }
            }
        }
        .navigationTitle("Attendees")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportToCSV) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(appSession.attendanceStore.eventAttendances.isEmpty)
            }
        }
        .sheet(isPresented: $isExporting) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            Task {
                await appSession.attendanceStore.fetchAttendance(for: event.id)
            }
        }
        .refreshable {
            await appSession.attendanceStore.fetchAttendance(for: event.id)
        }
    }
    
    private func exportToCSV() {
        var csvString = "Name,Entry Time,Exit Time\n"
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        
        for attendance in appSession.attendanceStore.eventAttendances {
            let user = appSession.clubStore.allUsers.first(where: { $0.id == attendance.userId })
            let name = user?.name ?? "Unknown User"
            let entry = attendance.entryTime.map { formatter.string(from: $0) } ?? "-"
            let exit = attendance.exitTime.map { formatter.string(from: $0) } ?? "-"
            
            // Escape commas in name
            let escapedName = name.contains(",") ? "\"\(name)\"" : name
            csvString += "\(escapedName),\(entry),\(exit)\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let safeTitle = event.title.replacingOccurrences(of: "[^A-Za-z0-9]", with: "_", options: .regularExpression)
        let fileURL = tempDir.appendingPathComponent("\(safeTitle)_Attendees.csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            exportFileURL = fileURL
            isExporting = true
        } catch {
            print("Error generating CSV: \(error)")
        }
    }
    
    @ViewBuilder
    private func destinationProfile(for user: User) -> some View {
        if user.role == .clubLead || user.role == .clubMember {
            LeadProfileView(user: user)
        } else {
            StudentProfileView(user: user)
        }
    }
    
    private func attendanceRow(user: User?, attendance: EventAttendance) -> some View {
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
