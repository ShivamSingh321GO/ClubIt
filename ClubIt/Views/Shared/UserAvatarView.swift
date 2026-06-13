import SwiftUI

struct UserAvatarView: View {
    let name: String
    let profileImg: String?
    let imageData: Data?
    var size: CGFloat = 60
    var iconSize: CGFloat = 30
    
    var body: some View {
        ZStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let profileImg = profileImg, profileImg.starts(with: "http"), let url = URL(string: profileImg) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure, .empty:
                        fallbackInitialsView
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let profileImg = profileImg, !profileImg.isEmpty && UIImage(named: profileImg) != nil {
                Image(profileImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                fallbackInitialsView
            }
        }
        .frame(width: size, height: size)
    }
    
    private var fallbackInitialsView: some View {
        Circle()
            .fill(LinearGradient(colors: [.indigo.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.primary)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(name: "Kavya", profileImg: nil, imageData: nil)
        UserAvatarView(name: "Technojam", profileImg: "technojamLogo", imageData: nil)
    }
}
