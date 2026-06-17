import SwiftUI

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
            formatter.timeStyle = .short
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let startOfDate = calendar.startOfDay(for: date)
            let startOfToday = calendar.startOfDay(for: Date())
            let components = calendar.dateComponents([.day], from: startOfDate, to: startOfToday)
            
            if let days = components.day, days < 7 {
                formatter.dateFormat = "EEEE"
            } else {
                formatter.dateFormat = "MM/dd/yy"
            }
        }
        return formatter.string(from: date)
    }
}
