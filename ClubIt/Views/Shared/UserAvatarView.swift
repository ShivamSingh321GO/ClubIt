import SwiftUI

struct UserAvatarView: View {
    let name: String
    let profileImg: String?
    let imageData: Data?
    var size: CGFloat = 60
    var iconSize: CGFloat = 30
    
    var body: some View {
        let effectiveProfileImg: String? = {
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if cleanName.contains("technojam") {
                return "technojamLogo"
            }
            if profileImg == "calendar" {
                return "person.3.fill"
            }
            return profileImg
        }()
        
        return ZStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let profileImg = effectiveProfileImg, profileImg.starts(with: "http"), let url = URL(string: profileImg) {
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
            } else if let profileImg = effectiveProfileImg, !profileImg.isEmpty && UIImage(systemName: profileImg) != nil {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.15))
                    Image(systemName: profileImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.accentColor)
                        .padding(size * 0.25)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else if let profileImg = effectiveProfileImg, !profileImg.isEmpty && UIImage(named: profileImg) != nil {
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
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.accentColor)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(name: "Kavya", profileImg: nil, imageData: nil)
        UserAvatarView(name: "Technojam", profileImg: "technojamLogo", imageData: nil)
    }
}
