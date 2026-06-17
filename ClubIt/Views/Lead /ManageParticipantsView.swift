import SwiftUI

struct ManageParticipantsView: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    
    @State private var selectedRole: ParticipantFilterRole = .all
    
    enum ParticipantFilterRole: String, CaseIterable, Identifiable {
        case all = "All"
        case students = "Students"
        case members = "Members"
        case leads = "Leads"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        let allRegistrations = appSession.registrationStore.getRegistrations(for: event.id)
        
        VStack(alignment: .leading, spacing: 0) {
            // Filter Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(allRegistrations.count) Total Registered")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                // Role Picker
                HStack(spacing: 8) {
                    ForEach(ParticipantFilterRole.allCases) { role in
                        let isSelected = selectedRole == role
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedRole = role
                            }
                        } label: {
                            Text(role.rawValue)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .frame(minWidth: 65)
                                .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill).opacity(0.5), in: Capsule())
                                .foregroundStyle(isSelected ? .white : .primary)
                                .glassEffect(in: .capsule)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            
            Divider()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if filteredRegistrations(allRegistrations).isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(selectedRole == .all ? "No participants have joined yet" : "No \(selectedRole.rawValue.lowercased()) have registered yet")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(filteredRegistrations(allRegistrations)) { registration in
                            if let user = appSession.clubStore.allUsers.first(where: { $0.id == registration.userId }) {
                                NavigationLink {
                                    destinationProfile(for: user)
                                } label: {
                                    ParticipantRow(user: user, registration: registration)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Participants")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        generateAndShare(forExcel: true)
                    } label: {
                        Label("Export as Excel Sheet", systemImage: "tablecells")
                    }
                    
                    Button {
                        generateAndShare(forExcel: false)
                    } label: {
                        Label("Export as Numbers Sheet", systemImage: "chart.bar.doc.horizontal")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                }
            }
        }
    }
    
    @MainActor
    private func generateAndShare(forExcel: Bool) {
        let allRegistrations = appSession.registrationStore.getRegistrations(for: event.id)
        let registrations = filteredRegistrations(allRegistrations)
        let allUsers = appSession.clubStore.allUsers
        
        var csvString = "Name,Role,Course,Year,Email,Phone"
        
        // Find all unique question labels for headers
        var uniqueQuestions: [String] = []
        for reg in registrations {
            if let answers = reg.answers {
                for key in answers.keys {
                    if !uniqueQuestions.contains(key) {
                        uniqueQuestions.append(key)
                    }
                }
            }
        }
        
        // Add question headers
        for question in uniqueQuestions {
            csvString += ",\"\(question.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        csvString += "\n"
        
        // Add data rows
        for reg in registrations {
            guard let user = allUsers.first(where: { $0.id == reg.userId }) else { continue }
            
            let name = user.name.replacingOccurrences(of: "\"", with: "\"\"")
            let role = user.role.rawValue.replacingOccurrences(of: "\"", with: "\"\"")
            let course = (user.course ?? "N/A").replacingOccurrences(of: "\"", with: "\"\"")
            let year = (user.year ?? "N/A").replacingOccurrences(of: "\"", with: "\"\"")
            let email = user.email.replacingOccurrences(of: "\"", with: "\"\"")
            let phone = (user.phoneNumber ?? "N/A").replacingOccurrences(of: "\"", with: "\"\"")
            
            var row = "\"\(name)\",\"\(role)\",\"\(course)\",\"\(year)\",\"\(email)\",\"\(phone)\""
            
            for question in uniqueQuestions {
                if let answer = reg.answers?[question] {
                    row += ",\"\(answer.replacingOccurrences(of: "\"", with: "\"\""))\""
                } else {
                    row += ",\"\""
                }
            }
            csvString += "\(row)\n"
        }
        
        // Save to temp files
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM_dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        let safeEventName = event.name.replacingOccurrences(of: " ", with: "_")
        let fileName = forExcel ? "\(safeEventName)_Participants_Excel_\(dateString).csv" : "\(safeEventName)_Participants_Numbers_\(dateString).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Present UIActivityViewController directly from the topmost UIViewController
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                // Handle iPad presentation
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = window
                        popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                }
                
                var topController = rootVC
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                topController.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting CSV: \(error)")
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
    
    private func filteredRegistrations(_ registrations: [IndividualRegistration]) -> [IndividualRegistration] {
        registrations.filter { registration in
            guard let user = appSession.clubStore.allUsers.first(where: { $0.id == registration.userId }) else { return false }
            
            switch selectedRole {
            case .all:
                return true
            case .students:
                return user.role == .student
            case .members:
                return user.role == .clubMember
            case .leads:
                return user.role == .clubLead
            }
        }
    }
}

struct SummaryStatCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(count)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

struct ParticipantRow: View {
    @Environment(AppSession.self) var appSession
    
    let user: User
    let registration: IndividualRegistration
    
    @State private var showAnswers = false
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Top Section
            HStack(alignment: .center, spacing: 14) {
                
                UserAvatarView(
                    name: user.name,
                    profileImg: user.profileImg,
                    imageData: user.imageData,
                    size: 52
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(user.course ?? "N/A") • \(user.year ?? "N/A")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if user.role == .clubLead {
                    Text("Host")
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
            }
            
            // Full-width divider
            if let answers = registration.answers, !answers.isEmpty {
                Divider()
                    .bold()
                
                Button {
                    showAnswers = true
                } label: {
                    HStack {
                        Label("Registration Answers", systemImage: "doc.text")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showAnswers) {
                    ParticipantAnswersView(
                        user: user,
                        registration: registration
                    )
                    .presentationDetents([.medium, .large])
                }
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 22))
    }
}

#Preview {
    NavigationStack {
        ManageParticipantsView(event: MockData.technoJamBundle.events[0])
            .environment(MockData.session(for: .clubLead))
    }
}
