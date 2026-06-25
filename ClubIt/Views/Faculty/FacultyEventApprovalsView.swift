import SwiftUI
import ClubItShared

struct FacultyEventApprovalsView: View {
    @Environment(AppSession.self) var appSession
    let eventId: UUID
    let userId: UUID
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [.blue.opacity(0.05), .clear], 
                         startPoint: .topLeading, 
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                let eventApprovals = appSession.approvalStore.approvals.filter { 
                    $0.eventId == eventId && $0.receiverId == userId && $0.status == .pending && $0.type != .budget
                }
                
                VStack(spacing: 20) {
                    if let event = appSession.eventStore.events.first(where: { $0.id == eventId }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.name)
                                .font(.title2.bold())
                            Text("Pending approval requests for this event")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    }
                    
                    if eventApprovals.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green.opacity(0.5))
                            Text("All Caught Up")
                                .font(.headline)
                            Text("No pending approvals for this event.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                        .glassEffect(in: .rect(cornerRadius: 30))
                        .padding(.top, 40)
                    } else {
                        ForEach(eventApprovals) { approval in
                            NavigationLink(destination: FacultyApprovalDetailView(approval: approval)) {
                                HStack(spacing: 16) {
                                    ApprovalTypeIcon(type: approval.type)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(approval.type.rawValue.capitalized)
                                            .font(.headline)
                                        Text("Review Request")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .glassEffect(in: .rect(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Event Approvals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ApprovalTypeIcon: View {
    let type: ApprovalType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.gradient.opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
        }
    }
    
    var icon: String {
        switch type {
        case .event: return "calendar"
        case .budget: return "indianrupeesign.circle"
        case .resource: return "box.truck"
        case .venue: return "mappin.and.ellipse"
        }
    }
    
    var color: Color {
        switch type {
        case .event: return .blue
        case .budget: return .green
        case .resource: return .accentColor
        case .venue: return .purple
        }
    }
}
