import SwiftUI

struct ChatBox: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @State private var messageText: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAttachmentMenu = false
    @State private var showChatInfo = false
    @State private var showAddSubChat = false
    @State private var subChatName = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        // Read messages directly inside body for proper Observation tracking
        let chatMessages = appSession.chatStore.messages[chat.id] ?? []
        
        VStack(spacing: 0) {
            headerView
            
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        
                        Text(todayDateString())
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                        
                        ForEach(chatMessages) { message in
                            let isCurrentUser = message.senderId == appSession.chatStore.userId
                            
                            MessageBubble(message: message, isCurrentUser: isCurrentUser)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.1, anchor: isCurrentUser ? .bottomTrailing : .bottomLeading)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                        
                        if let lastMessage = chatMessages.last, lastMessage.senderId == appSession.chatStore.userId {
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isMessageFieldFocused = false
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chatMessages.count) {
                    if let lastId = chatMessages.last?.id {
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
        .sheet(isPresented: $showAttachmentMenu) {
            AttachmentMenu { type in
                // Handle attachment mock logic
                print("Selected attachment: \(type)")
            }
            .presentationDetents([.height(300), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
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
    
    // MARK: - Header
    private var headerView: some View {
        ZStack(alignment: .center) {
            // Center content
            Button {
                showChatInfo = true
            } label: {
                VStack(spacing: 4) {
                    avatarView
                    Text(chat.displayName)
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
                        .foregroundColor(.primary)
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
                Circle().fill(Color(.secondarySystemFill))
                Image(systemName: chat.icon ?? "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            }
            
            HStack(spacing: 8) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .focused($isMessageFieldFocused)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(.primary)
                    .submitLabel(.send)
                    .onSubmit {
                        sendCurrentMessage()
                    }
                
                Button {
                    sendCurrentMessage()
                } label: {
                    if messageText.isEmpty {
                        Image(systemName: "mic")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color.gray)
                            .padding(.trailing, 12)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .padding(.trailing, 4)
                    }
                }
            }
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.chatBackground)
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
