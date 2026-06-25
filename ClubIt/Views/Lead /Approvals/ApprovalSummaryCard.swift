import SwiftUI
import ClubItShared

struct ApprovalSummaryCard: View {
    let title: String
    let subtitle: String
    var eventDate: String? = nil
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 55, height: 55)
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let eventDate = eventDate {
                        EventDateTag(dateString: eventDate)
                            .padding(.bottom, 2)
                    }

                    Text("Approval Request")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.body)
                        .bold()
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            
            HStack {
                Spacer()
                Button(action: action) {
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
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.4))
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

#Preview {
    ZStack {
        Color.f2Background.ignoresSafeArea()
        VStack {
            ApprovalSummaryCard(
                title: "Annual Tech Summit 2025",
                subtitle: "by Technojam • 2 hours ago",
                action: {}
            )
            .padding()
        }
    }
}
