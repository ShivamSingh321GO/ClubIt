import SwiftUI

struct ManageParticipantsView: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    
    var body: some View {
        let registrations = appSession.registrationStore.getRegistrations(for: event.id)
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header Summary
                HStack(spacing: 16) {
                    SummaryStatCard(title: "Total Joined", count: "\(registrations.count)", icon: "person.2.fill", color: .blue)
                    SummaryStatCard(title: "Confirmed", count: "\(registrations.filter { $0.status == .confirmed }.count)", icon: "checkmark.circle.fill", color: .green)
                }
                
                HStack {
                    Text("Participant List")
                        .font(.headline)
                    Spacer()
                    
                    if registrations.contains(where: { $0.status != .confirmed }) {
                        Button {
                            withAnimation {
                                appSession.registrationStore.confirmAll(for: event.id)
                            }
                        } label: {
                            Text("Confirm All")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.gradient)
                                .clipShape(Capsule())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.top, 8)
                
                if registrations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No participants yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .glassEffect(in: .rect(cornerRadius: 24))
                } else {
                    VStack(spacing: 16) {
                        ForEach(registrations) { registration in
                            if let user = appSession.clubStore.allUsers.first(where: { $0.id == registration.userId }) {
                                ParticipantRow(user: user, registration: registration)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Manage Participants")
        .navigationBarTitleDisplayMode(.inline)
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
            
            // Status Tag
            Text(registration.status.rawValue.capitalized)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .foregroundColor(statusColor)
                .clipShape(Capsule())
            
            Menu {
                Button("Confirm") {
                    appSession.registrationStore.updateStatus(registrationId: registration.id, status: .confirmed)
                }
                Button("Cancel", role: .destructive) {
                    appSession.registrationStore.updateStatus(registrationId: registration.id, status: .cancelled)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(8)
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
