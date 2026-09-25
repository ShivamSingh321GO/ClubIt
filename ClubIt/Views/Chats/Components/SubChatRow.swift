import SwiftUI
import ClubItShared

struct SubChatRow: View {
    let chat: Chat
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            UserAvatarView(
                name: chat.displayName,
                profileImg: chat.icon,
                imageData: nil,
                size: 36
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !chat.lastMessage.isEmpty {
                    Text(chat.lastMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString(from: chat.lastMessageAt ?? chat.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .padding(.horizontal, 4)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.trailing, 16)
        .padding(.leading, 72)
        .background(Color(.systemBackground))
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
        var calendar = Calendar.current
        if let istTimeZone = TimeZone(identifier: "Asia/Kolkata") {
            calendar.timeZone = istTimeZone
        }
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let currentYear = calendar.component(.year, from: Date())
            let dateYear = calendar.component(.year, from: date)
            if currentYear == dateYear {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
}
