import SwiftUI

struct ChatRow: View {
    let chat: Chat
    var onToggleExpansion: () -> Void
    var onTogglePin: () -> Void
    var onDelete: () -> Void
    var onAddChat: (() -> Void)? = nil
    
    // For random gradient generation
    private let colors: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo]
    private var randomGradient: LinearGradient {
        let hash = abs(chat.id.hashValue)
        let color1 = colors[hash % colors.count]
        let color2 = colors[(hash / 10) % colors.count]
        return LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar/Icon
            ZStack(alignment: .bottomTrailing) {
                chatIcon
                
                // Online indicator for individual chats
                if chat.type == .individual {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(Color.chatBackground, lineWidth: 2)
                        )
                        .offset(x: -2, y: -2)
                }
            }
            .frame(width: 54, height: 54)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(chat.name)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Timestamp (Mocked here since we don't have lastMessageTime on Chat model, using createdAt)
                    Text(timeString(from: chat.createdAt))
                        .font(.caption)
                        .foregroundStyle(chat.unreadCount > 0 ? Color.chatAccent : .secondary)
                        .fontWeight(chat.unreadCount > 0 ? .semibold : .regular)
                }
                
                HStack {
                    if !chat.lastMessage.isEmpty {
                        Text(chat.lastMessage)
                            .font(.subheadline)
                            .foregroundStyle(chat.unreadCount > 0 ? .primary : .secondary)
                            .fontWeight(chat.unreadCount > 0 ? .medium : .regular)
                            .lineLimit(1)
                    } else {
                        Text("Tap to start chatting")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 6)
                            .background(Color.chatAccent)
                            .clipShape(Capsule())
                    } else if chat.type == .event {
                        Image(systemName: chat.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private var chatIcon: some View {
        if chat.type == .event {
            ZStack {
                Color(white: 0.15)
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
        } else if chat.type == .group {
            ZStack {
                Color(white: 0.15)
                Image(systemName: "person.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
        } else if let icon = chat.icon {
            if icon.contains("https") {
                AsyncImage(url: URL(string: icon)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color(.secondarySystemBackground))
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
            } else if UIImage(named: icon) != nil {
                Image(icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(Color(.secondarySystemFill))
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
            }
        } else {
            ZStack {
                Color(white: 0.15)
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
        }
    }
}
