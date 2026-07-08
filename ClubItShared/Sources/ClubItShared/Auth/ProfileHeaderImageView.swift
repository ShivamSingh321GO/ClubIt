import SwiftUI
import UIKit

public struct ProfileHeaderImageView: View {
    public var name: String
    public var profileImg: String?
    public var imageData: Data?
    public var size: CGFloat
    
    public init(name: String, profileImg: String?, imageData: Data?, size: CGFloat = 32) {
        self.name = name
        self.profileImg = profileImg
        self.imageData = imageData
        self.size = size
    }
    
    // Convenience initializer for User model
    public init(user: User?, size: CGFloat = 32) {
        self.name = user?.name ?? ""
        self.profileImg = user?.profileImg
        self.imageData = user?.imageData
        self.size = size
    }
    
    private var initial: String {
        guard !name.isEmpty else {
            return "U"
        }
        return String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
    }
    
    private var backgroundColor: Color {
        guard !name.isEmpty else {
            return .blue
        }
        // Stable dynamic background colors based on name hash
        let hash = abs(name.hashValue)
        let colors: [Color] = [.blue, .purple, .orange, .pink, .teal, .green, .indigo]
        return colors[hash % colors.count]
    }
    
    private var effectiveProfileImg: String? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanName.contains("technojam") {
            return "technojamLogo"
        }
        if profileImg == "calendar" {
            return "person.3.fill"
        }
        return profileImg
    }
    
    public var body: some View {
        ZStack {
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
                    Circle().fill(Color.blue.opacity(0.15))
                    Image(systemName: profileImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.blue)
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
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}
