import SwiftUI

struct ClubHeaderView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    let event: Event
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: event, isMyEvent: false)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.gradient.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(String(club.name.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(club.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(16)
            .glassEffect(in: .rect(cornerRadius: 24))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
