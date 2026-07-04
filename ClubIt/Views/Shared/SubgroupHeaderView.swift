import SwiftUI
import ClubItShared

struct SubgroupHeaderView: View {
    @Environment(AppSession.self) var appSession
    let subgroup: Subgroup
    let event: Event
    var isEditedAfterApproval: Bool = false
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: event, isMyEvent: false)) {
            HStack(spacing: 16) {
                ZStack {
                if let bannerUrl = event.bannerImage, let url = URL(string: bannerUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.accentColor.gradient.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Text(String(subgroup.name.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.accentColor)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.accentColor.gradient.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(String(subgroup.name.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(event.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            
                        if isEditedAfterApproval {
                            Text("Edited")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(subgroup.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
//                Image(systemName: "chevron.right")
//                    .font(.caption.bold())
//                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(16)
            .contentShape(.rect)
            .glassEffect(in: .rect(cornerRadius: 24))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
