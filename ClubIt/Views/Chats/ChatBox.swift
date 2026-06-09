import SwiftUI

struct ChatBox: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @State private var messageText: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var showAttachmentMenu = false
    @State private var dragOffset: CGFloat = 0
    @State private var showChatInfo = false
    
    var messages: [Message] {
        appSession.chatStore.messages[chat.id] ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                            let isCurrentUser = message.senderId == appSession.chatStore.userId
                            
                            ZStack(alignment: .trailing) {
                                MessageBubble(message: message, isCurrentUser: isCurrentUser)
                                    .offset(x: dragOffset)
                                
                                Text(timeString(for: message.createdAt))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(width: 60, alignment: .leading)
                                    .offset(x: 60 + dragOffset)
                            }
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.1, anchor: isCurrentUser ? .bottomTrailing : .bottomLeading)
                                    .combined(with: .opacity)
                                    .combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
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
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.width < 0 {
                                    // limit drag offset
                                    dragOffset = max(value.translation.width, -60)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                    )
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
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .background(Color.chatBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            appSession.chatStore.markAsRead(for: chat.id)
        }
        .sheet(isPresented: $showAttachmentMenu) {
            AttachmentMenu { type in
                // Handle attachment mock logic
                print("Selected attachment: \(type)")
            }
        }
        .sheet(isPresented: $showChatInfo) {
            NavigationStack {
                ChatInfoView(chat: chat)
            }
            .presentationDetents([.large])
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        ZStack(alignment: .center) {
            // Center content
            Button {
                showChatInfo = true
            } label: {
                VStack(spacing: 4) {
                    avatarView
                    Text(chat.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
            
            // Back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                Spacer()
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.chatBackground)
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
                Circle().fill(Color(white: 0.15))
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 45, height: 45)
        .clipShape(Circle())
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Button {
                showAttachmentMenu = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(Color(white: 0.85))
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .padding(.bottom, 6)
            
            HStack(spacing: 8) {
                TextField("iMessage", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                
                Button {
                    if !messageText.isEmpty {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            appSession.chatStore.sendMessage(messageText, to: chat.id)
                            messageText = ""
                        }
                    }
                } label: {
                    if messageText.isEmpty {
                        Image(systemName: "mic")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color.gray)
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue) // Native blue for send arrow
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                    }
                }
            }
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.chatBackground)
    }
    
    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let session = AppSession()
    let mockChat = session.chatStore.chats[0]
    NavigationStack {
        ChatBox(chat: mockChat)
            .environment(session)
    }
}
