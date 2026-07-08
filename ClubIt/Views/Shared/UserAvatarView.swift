import SwiftUI
import ClubItShared

struct UserAvatarView: View {
    let name: String
    let profileImg: String?
    let imageData: Data?
    var size: CGFloat = 60
    var iconSize: CGFloat = 30
    
    var body: some View {
        ProfileHeaderImageView(name: name, profileImg: profileImg, imageData: imageData, size: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(name: "Kavya", profileImg: nil, imageData: nil)
        UserAvatarView(name: "Technojam", profileImg: "technojamLogo", imageData: nil)
    }
}
