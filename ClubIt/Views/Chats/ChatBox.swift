import SwiftUI

struct ChatBox: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @State private var messageText: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showChatInfo = false
    @State private var showAddSubChat = false
    @State private var subChatName = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        let chatMessages = appSession.chatStore.messages[chat.id] ?? []
        let otherParticipantId = appSession.chatStore.chatParticipants[chat.id]?
            .first(where: { $0.userId != appSession.chatStore.userId })?.userId
        let isOnline = otherParticipantId.map { appSession.chatStore.onlineUserIds.contains($0) } ?? false
        
        VStack(spacing: 0) {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        // Date header
                        Text(todayDateString())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        ForEach(chatMessages) { message in
                            let isCurrentUser = message.senderId == appSession.chatStore.userId
                            
                            MessageBubble(message: message, isCurrentUser: isCurrentUser)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8, anchor: isCurrentUser ? .bottomTrailing : .bottomLeading)
                                        .combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // Delivered indicator
                        if let lastMessage = chatMessages.last, lastMessage.senderId == appSession.chatStore.userId {
                            HStack {
                                Spacer()
                                Text("Delivered")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 16)
                            }
                            .padding(.top, 2)
                        }
                        
                        // Typing indicator
                        if let typingUsers = appSession.chatStore.typingUsers[chat.id], !typingUsers.isEmpty {
                            HStack(spacing: 6) {
                                TypingDotsView()
                                Text("typing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .defaultScrollAnchor(.bottom)
                .onChange(of: chatMessages.count) {
                    if let lastId = chatMessages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        if let lastId = chatMessages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onTapGesture {
                    isMessageFieldFocused = false
                }
            }
            
            Divider()
            
            // Input Bar
            inputBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .principal) {
                Button {
                    showChatInfo = true
                } label: {
                    VStack(spacing: 2) {
                        ZStack(alignment: .bottomTrailing) {
                            UserAvatarView(name: chat.displayName, profileImg: chat.icon, imageData: nil, size: 34)
                            
                            if chat.type == .individual && isOnline {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
                                    .offset(x: 1, y: 1)
                            }
                        }
                        
                        Text(chat.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task {
            appSession.chatStore.activeChatId = chat.id
            await appSession.chatStore.fetchMessages(for: chat.id)
            await appSession.chatStore.markAsRead(for: chat.id)
        }
        .onDisappear {
            appSession.chatStore.activeChatId = nil
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await appSession.chatStore.markAsRead(for: chat.id)
                }
            }
        }

        .sheet(isPresented: $showChatInfo) {
            ChatInfoView(chat: chat)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showAddSubChat) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Chat Name", text: $subChatName)
                    }
                }
                .navigationTitle("New Sub-Chat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showAddSubChat = false
                            subChatName = ""
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            appSession.chatStore.addSubChat(name: subChatName, for: chat.id)
                            showAddSubChat = false
                            subChatName = ""
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primary)
                        }
                        .disabled(subChatName.isEmpty)
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
    }
    

    
    private var initialsCircle: some View {
        ZStack {
            Circle().fill(
                LinearGradient(
                    colors: [Color(.systemGray3), Color(.systemGray4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            Text(String(chat.displayName.prefix(1)).uppercased())
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Text field in capsule
            HStack(spacing: 8) {
                TextField("iMessage", text: $messageText, axis: .vertical)
                    .focused($isMessageFieldFocused)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .submitLabel(.send)
                    .onChange(of: messageText) { _, newText in
                        if !newText.isEmpty {
                            appSession.chatStore.sendTypingEvent(chatId: chat.id)
                        }
                    }
                    .onSubmit {
                        sendCurrentMessage()
                    }
            }
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
                    .overlay(Capsule().stroke(Color(.systemGray4), lineWidth: 0.5))
            )
            
            // Send button
            if !messageText.isEmpty {
                Button {
                    sendCurrentMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.15), value: messageText.isEmpty)
    }
    
    // MARK: - Send Message
    private func sendCurrentMessage() {
        guard !messageText.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appSession.chatStore.sendMessage(messageText, to: chat.id)
            messageText = ""
        }
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return "Today " + formatter.string(from: Date())
    }
}

// MARK: - Typing Dots Animation
struct TypingDotsView: View {
    @State private var dotOffsets: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 7, height: 7)
                    .offset(y: dotOffsets[index])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
                ) {
                    dotOffsets[i] = -5
                }
            }
        }
    }
}

#Preview {
    let session = AppSession()
    NavigationStack {
        ChatBox(chat: Chat(
            id: UUID(),
            type: .individual,
            name: "Preview Chat",
            createdBy: UUID(),
            createdAt: Date()
        ))
        .environment(session)
    }
}
