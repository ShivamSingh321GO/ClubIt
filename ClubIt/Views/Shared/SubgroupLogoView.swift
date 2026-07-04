import SwiftUI
import ClubItShared

struct SubgroupLogoView: View {
    let logo: String
    let imageData: Data?
    var size: CGFloat = 60
    var iconSize: CGFloat = 35
    
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if logo.starts(with: "http"), let url = URL(string: logo) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure, .empty:
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                            ProgressView()
                        }
                        .frame(width: size, height: size)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if !logo.isEmpty && UIImage(named: logo) != nil {
                Image(logo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "flame.fill")
                    .font(.system(size: iconSize * 0.8).bold())
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SubgroupLogoView(logo: "technojamLogo", imageData: nil)
        SubgroupLogoView(logo: "", imageData: nil)
        SubgroupLogoView(logo: "invalid", imageData: nil)
    }
}
