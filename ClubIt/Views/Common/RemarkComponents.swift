import SwiftUI

struct RemarkConversationView: View {
    @Environment(AppSession.self) var appSession
    let remarks: [Remark]
    @State private var showAllRemarks: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let displayedRemarks = showAllRemarks ? remarks : Array(remarks.suffix(3))
            
            ForEach(displayedRemarks) { remark in
                let isCurrentUser = remark.authorId == appSession.currentUser?.id
                let authorName = appSession.clubStore.allUsers.first(where: { $0.id == remark.authorId })?.name ?? "Unknown"
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                    HStack {
                        if !isCurrentUser {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(String(authorName.prefix(1)))
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
                        
                        if isCurrentUser {
                            Text("You")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(remark.text)
                        .font(.subheadline)
                        .foregroundColor(isCurrentUser ? .white : .primary.opacity(0.8))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isCurrentUser ? Color.blue : Color.primary.opacity(0.05))
                        )
                        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                }
            }
            
            if remarks.count > 3 && !showAllRemarks {
                Button {
                    withAnimation { showAllRemarks = true }
                } label: {
                    Text("Show \(remarks.count - 3) more remarks...")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            } else if showAllRemarks && remarks.count > 3 {
                Button {
                    withAnimation { showAllRemarks = false }
                } label: {
                    Text("Show less")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ReplyInputView: View {
    @Binding var replyText: String
    let onSend: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(spacing: 12) {
                TextField("Type your reply...", text: $replyText)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(replyText.isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(replyText.isEmpty)
                
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 12)
        }
    }
}
