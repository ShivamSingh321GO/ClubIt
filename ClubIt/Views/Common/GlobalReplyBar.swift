import SwiftUI
import ClubItShared

struct GlobalReplyBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onCancel: () -> Void
    var placeholder: String = "Type your reply..."
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }
            
            HStack(spacing: 6) {
                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(text.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .clipShape(Circle())
                        .shadow(color: (text.trimmingCharacters(in: .whitespaces).isEmpty ? Color.clear : Color.blue).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.trailing, 4)
            }
            .background(Color.primary.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.primary.opacity(0.1)),
                    alignment: .top
                )
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
