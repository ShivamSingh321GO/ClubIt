import SwiftUI

struct RemarkConversationView: View {
    @Environment(AppSession.self) var appSession
    let approvalId: UUID
    @State private var showAllRemarks: Bool = false
    
    var remarks: [RemarkMessage] {
        appSession.approvalStore.remarkMessages[approvalId] ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let displayedRemarks = showAllRemarks ? remarks : Array(remarks.suffix(3))
            
            ForEach(displayedRemarks) { remark in
                let isCurrentUser = remark.authorId == appSession.currentUser?.id
                let authorName: String = {
                    let name = appSession.clubStore.allUsers.first(where: { $0.id == remark.authorId })?.name ?? "Unknown"
                    if name.lowercased() == "kavya" { return "Kavya (Club Lead)" }
                    if name.lowercased() == "aryan" { return "Aryan (Vice President)" }
                    return name
                }()
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    HStack {
                        if !isCurrentUser {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(authorName.isEmpty ? "U" : String(authorName.prefix(1)))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.orange)
                                )
                            
                            Text(authorName)
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text(formatDate(remark.createdAt))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(remark.content)
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 4)
            }
            
            if remarks.count > 3 && !showAllRemarks {
                Button(action: { withAnimation { showAllRemarks = true } }) {
                    Text("Show \(remarks.count - 3) more remarks...")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
                .padding(.leading, 4)
            }
        }
        .onAppear {
            Task {
                try? await appSession.approvalStore.fetchRemarks(for: approvalId)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ReplyInputView: View {
    @Binding var replyText: String
    var onSend: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $replyText)
                .frame(height: 80)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Send Reply", action: onSend)
                    .buttonStyle(.borderedProminent)
                    .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
}
