import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isCurrentUser ? Color.green : Color(.secondarySystemBackground))
                .foregroundStyle(isCurrentUser ? .white : .primary)
                .clipShape(BubbleShape(isCurrentUser: isCurrentUser))
            
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal, 12)
    }
}


struct BubbleShape: Shape {
    let isCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: 18, height: 18))
        return Path(path.cgPath)
    }
}
