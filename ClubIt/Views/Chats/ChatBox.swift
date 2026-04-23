import SwiftUI

struct ChatBox: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @State private var messageText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var messages: [Message] {
        appSession.chatStore.messages[chat.id] ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            headerView
            
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        Text("iMessage")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        
                        Text("Today 12:08 AM") // Mock time
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                        
                        ForEach(messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderId == appSession.chatStore.userId)
                                .id(message.id)
                        }
                        
                        if let lastMessage = messages.last, lastMessage.senderId == appSession.chatStore.userId {
                            HStack {
                                Spacer()
                                Text("Delivered")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 20)
                            }
                            .padding(.top, -8)
                        }
                        
                    }
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) {
                    if let lastId = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Bar
            inputBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.systemBackground))
        .onAppear {
            appSession.chatStore.markAsRead(for: chat.id)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .bold()
//                        .font(.title3)
//                        .foregroundStyle(.goldenBrown)
                        .padding()
                        .glassEffect(in : .circle)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Avatar
                avatarView
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 44, height: 44)
                    .padding(.trailing, 16)
            }
            
            HStack(spacing: 4) {
                Text(chat.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .clipShape(Capsule())
        }
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
    
    private var avatarView: some View {
        ZStack {
            if let icon = chat.icon, icon.contains("https") {
                AsyncImage(url: URL(string: icon)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
            } else {
                Circle().fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(chat.name.prefix(2)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 45, height: 45)
        .clipShape(Circle())
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            Button {
                // Attachments
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            
            HStack {
                TextField("iMessage", text: $messageText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Spacer()
                
                Image(systemName: "waveform")
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(.separator), lineWidth: 0.5))
            
            if !messageText.isEmpty {
                Button {
                    appSession.chatStore.sendMessage(messageText, to: chat.id)
                    messageText = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    let session = AppSession()
    let mockChat = session.chatStore.chats[0]
    return NavigationStack {
        ChatBox(chat: mockChat)
            .environment(session)
    }
}
