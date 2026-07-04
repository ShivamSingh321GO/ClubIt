import SwiftUI
import ClubItShared

struct MessageBubble: View {
    @Environment(AppSession.self) private var appSession
    let message: Message
    let isCurrentUser: Bool
    let isGroupChat: Bool
    
    // Whether the previous message was from the same sender (to avoid repeating the name)
    // Whether the previous message was from the same sender (to avoid repeating the name)
    var isConsecutive: Bool = false
    
    // Whether the sender is the creator of the event chat
    var isOrganizer: Bool = false
    
    private var systemMessageText: String {
        var cleanContent = message.content.replacingOccurrences(of: "[System]: ", with: "")
        
        // Standardize any historic "admin" messages to "organizer"
        cleanContent = cleanContent.replacingOccurrences(of: "was added by the admin", with: "was added by the organizer")
        cleanContent = cleanContent.replacingOccurrences(of: "were added by the admin", with: "were added by the organizer")
        
        let chat = appSession.chatStore.chats.first(where: { $0.id == message.chatId })
        let isCurrentChatCreator = chat?.createdBy == appSession.chatStore.userId
        
        let currentUserName = appSession.currentUser?.name ?? ""
        
        // If the viewer is the creator/organizer of the chat, show "[Name] was added" instead of "[Name] was added by the organizer"
        if isCurrentChatCreator {
            cleanContent = cleanContent.replacingOccurrences(of: "was added by the organizer", with: "was added")
            cleanContent = cleanContent.replacingOccurrences(of: "were added by the organizer", with: "were added")
        }
        
        if !currentUserName.isEmpty && cleanContent.hasPrefix(currentUserName) {
            var display = cleanContent.replacingOccurrences(of: currentUserName, with: "You")
            display = display.replacingOccurrences(of: "You joined the chat", with: "You joined the chat")
            display = display.replacingOccurrences(of: "You was added by the organizer", with: "You were added by the organizer")
            display = display.replacingOccurrences(of: "You was added", with: "You were added")
            return display
        }
        
        if cleanContent == "All subgroup members were added by the organizer" {
            if !isCurrentChatCreator {
                return "You were added by the organizer"
            }
        }
        
        return cleanContent
    }
    
    private var senderUser: User? {
        appSession.subgroupStore.allUsers.first(where: { $0.id == message.senderId })
    }
    
    var body: some View {
        if message.content.hasPrefix("[System]: ") {
            HStack {
                Spacer()
                Text(systemMessageText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        } else {
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 6) {
                    if isCurrentUser { Spacer(minLength: 60) }
                    
                    // Show avatar for group chats on other users' first message in a group
                    if isGroupChat && !isCurrentUser && !isConsecutive {
                        UserAvatarView(
                            name: senderUser?.name ?? "?",
                            profileImg: senderUser?.profileImg,
                            imageData: senderUser?.imageData,
                            size: 28
                        )
                    } else if isGroupChat && !isCurrentUser {
                        // Invisible spacer to keep alignment
                        Color.clear.frame(width: 28, height: 28)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Show sender name + organizer tag for group chats
                        if isGroupChat && !isCurrentUser && !isConsecutive {
                            Text(senderLabel(for: senderUser))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(senderColor(for: message.senderId))
                        }
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            Text(message.content)
                                .font(.body)
                            
                            Text(timeString(for: message.createdAt))
                                .font(.system(size: 10))
                                .foregroundStyle(isCurrentUser ? Color.white.opacity(0.8) : Color.gray)
                                .offset(y: 2)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .contextMenu {
                        if isCurrentUser {
                            Button(role: .destructive) {
                                appSession.chatStore.deleteMessage(messageId: message.id, chatId: message.chatId)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    if !isCurrentUser { Spacer(minLength: 60) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, isConsecutive ? 1 : 12)
            .padding(.bottom, 1)
        }
    }
    
    // MARK: - Sender Label
    
    private func senderLabel(for user: User?) -> String {
        guard let user = user else { return "Unknown" }
        
        if isOrganizer {
            return "\(user.name) (Organizer)"
        }
        
        return user.name
    }
    
    // MARK: - Sender Color (consistent per user)
    
    private func senderColor(for senderId: UUID) -> Color {
        let colors: [Color] = [
            .blue, .purple, .orange, .pink, .teal, .indigo, .mint, .cyan, .brown, .green
        ]
        let hash = abs(senderId.hashValue)
        return colors[hash % colors.count]
    }
    
    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
