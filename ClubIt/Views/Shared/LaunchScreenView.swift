import SwiftUI
import ClubItShared

struct LaunchScreenView: View {
    @Binding var showLaunchScreen: Bool
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.0
    @State private var iconYOffset: CGFloat = 0.0
    @State private var appNameOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // Icon
            if let appIcon = Bundle.main.icon {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .primary.opacity(0.1), radius: 10, x: 0, y: 5)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .offset(y: iconYOffset)
            } else {
                Image(systemName: "cube.transparent.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.accentColor)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .offset(y: iconYOffset)
            }
            
            // Text Container
            VStack(spacing: 8) {
                Text("ClubIt")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.primary)
                    .opacity(appNameOpacity)
                
                Text("Discover and manage campus subgroups effortlessly")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
            }
            .offset(y: 70)
        }
        .onAppear {
            // 1. Icon grows from small to big
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.2
                iconOpacity = 1.0
            }
            
            // 2. Icon moves up, App Name appears
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                iconYOffset = -70
                appNameOpacity = 1.0
            }
            
            // 3. Tagline appears shortly after
            withAnimation(.easeIn(duration: 0.5).delay(1.3)) {
                textOpacity = 1.0
            }
            
            // 4. Premium subtle fade transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    iconScale = 1.1
                    iconYOffset -= 15
                    iconOpacity = 0.0
                    appNameOpacity = 0.0
                    textOpacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
