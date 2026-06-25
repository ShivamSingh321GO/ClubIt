import SwiftUI
import ClubItShared

struct HomeApprovalCard: View {
    @Environment(AppSession.self) var appSession
    let approval: Approval
    var showTrack: Bool = true
    var onSeeAll: (() -> Void)? = nil
    
    var body: some View {
        let eventName = appSession.eventStore.events.first(where: { $0.id == approval.eventId })?.name ?? "Event Info"

        
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(approvalTypeColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 55, height: 55)
                    
                    Image(systemName: approvalIcon)
                        .foregroundColor(approvalTypeColor)
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(approval.type.rawValue.capitalized) Approval")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(eventName)
                        .font(.body.bold())
                        .foregroundColor(.primary)
                    
                    Text("by you • \(formatDate(approval.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            
            if showTrack {
                ApprovalStatusTrack(approval: approval)
                
                if appSession.currentRole == .groupLead && approval.type == .budget && approval.status == .pending {
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                try? await appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                            }
                        } label: {
                            Text("Approve")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            Task {
                                try? await appSession.approvalStore.updateApproval(id: approval.id, status: .rejected)
                            }
                        } label: {
                            Text("Reject")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                HStack {
                    Spacer()
                    Button(action: { onSeeAll?() }) {
                        Text("All approvals")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.4))
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    var approvalTypeColor: Color {
        switch approval.type {
        case .event: return .accentColor
        case .budget: return .green
        case .venue: return .red
        default: return .blue
        }
    }
    
    var approvalIcon: String {
        switch approval.type {
        case .event: return "calendar"
        case .budget: return "indianrupeesign.circle"
        case .venue: return "mappin.and.ellipse"
        case .resource: return "archivebox"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}



#Preview {
    ZStack {
        Color.f2Background.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 20) {

                HomeApprovalCard(
                    approval: MockData.sampleApprovals[0],
                    showTrack: true
                )
                
                HomeApprovalCard(
                    approval: MockData.sampleApprovals[1],
                    showTrack: false
                )
            }
            .padding()
        }
    }
}
