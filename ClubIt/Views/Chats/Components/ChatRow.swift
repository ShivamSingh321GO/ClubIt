import SwiftUI

struct ChatRow: View {
    @Environment(AppSession.self) private var appSession
    
    let chat: Chat
    var onToggleExpansion: () -> Void
    var onTogglePin: () -> Void
    var onDelete: () -> Void
    var onAddChat: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                chatIcon
                    .frame(width: 52, height: 52)
                
                if chat.type == .individual {
                    let otherParticipantId = appSession.chatStore.chatParticipants[chat.id]?
                        .first(where: { $0.userId != appSession.chatStore.userId })?.userId
                    let isOnline = otherParticipantId.map { appSession.chatStore.onlineUserIds.contains($0) } ?? false
                    
                    if isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2.5))
                            .offset(x: 2, y: 2)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(chat.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.type == .event {
                        let totalUnread = chat.unreadCount + appSession.chatStore.getSubChats(for: chat.id).reduce(0) { $0 + $1.unreadCount }
                        if totalUnread > 0 {
                            Text("\(totalUnread)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .padding(.horizontal, 5)
                                .background(Color.goldenBrown)
                                .clipShape(Capsule())
                        }
                    } else {
                        Text(timeString(from: chat.lastMessageAt ?? chat.createdAt))
                            .font(.subheadline)
                            .foregroundStyle(chat.unreadCount > 0 ? Color.goldenBrown : .secondary)
                    }
                }
                
                HStack {
                    if !chat.lastMessage.isEmpty {
                        Text(chat.lastMessage)
                            .font(.subheadline)
                            .foregroundStyle(chat.unreadCount > 0 ? .primary : .secondary)
                            .fontWeight(chat.unreadCount > 0 ? .medium : .regular)
                            .lineLimit(2)
                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if chat.type == .event {
                        Button(action: {
                            withAnimation(.spring()) {
                                onToggleExpansion()
                            }
                        }) {
                            Image(systemName: chat.isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 5)
                            .background(Color.goldenBrown)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    private func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MM/dd/yy"
        }
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private var chatIcon: some View {
        if chat.type == .event {
            ZStack {
                Circle().fill(Color(.systemGray5))
                Image(systemName: "person.3.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
            }
            .clipShape(Circle())
        } else if chat.type == .group {
            ZStack {
                Circle().fill(Color(.systemGray5))
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
            }
            .clipShape(Circle())
        } else {
            UserAvatarView(name: chat.displayName, profileImg: chat.icon, imageData: nil, size: 52)
        }
    }
    
    private var initialsAvatar: some View {
        ZStack {
            Circle().fill(
                LinearGradient(
                    colors: [Color(.systemGray3), Color(.systemGray4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            Text(String(chat.displayName.prefix(1)).uppercased())
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
