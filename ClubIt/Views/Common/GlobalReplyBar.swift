import SwiftUI

struct GlobalReplyBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onCancel: () -> Void
    var placeholder: String = "Type your reply..."
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField(placeholder, text: $text)
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .padding(10)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
