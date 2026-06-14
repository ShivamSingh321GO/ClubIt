import SwiftUI

struct SubChatRow: View {
    let chat: Chat
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
                .frame(width: 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(chat.lastMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString(from: chat.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.goldenBrown)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.trailing, 16)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
