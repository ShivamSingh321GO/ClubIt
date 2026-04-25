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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Participants")
                            .font(.title2.bold())
                        Text("\(allRegistrations.count) Total Registered")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Role Picker
                HStack(spacing: 8) {
                    ForEach(ParticipantFilterRole.allCases) { role in
                        let isSelected = selectedRole == role
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedRole = role
                            }
                        } label: {
                            Text(role.rawValue)
                                .font(.footnote.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.orange : Color.orange.opacity(0.1))
                                .foregroundStyle(isSelected ? .white : .orange)
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
                            Text("No \(selectedRole.rawValue.lowercased()) found")
                                .font(.subheadline)
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
        .navigationBarTitleDisplayMode(.inline)
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.orange.gradient.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(String(user.name.prefix(1)))
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.subheadline.bold())
                Text("\(user.course) • \(user.year)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Spacer()
            
            if user.role == .clubLead {
                // For leads, show a Host badge
                Text("Host")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .glassEffect(in: .rect(cornerRadius: 18))
    }
    
    private var statusColor: Color {
        switch registration.status {
        case .confirmed: return .green
        case .pending: return .orange
        case .cancelled: return .red
        }
    }
}

#Preview {
    NavigationStack {
        ManageParticipantsView(event: MockData.technoJamBundle.events[0])
            .environment(MockData.session(for: .clubLead))
    }
}
