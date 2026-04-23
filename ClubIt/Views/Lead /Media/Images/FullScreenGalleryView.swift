import SwiftUI

struct FullScreenGalleryView: View {
    let images: [ClubImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    MediaImageView(media: images[index])
                        .scaledToFit()
                        .tag(index)
                        .interactiveDismissDisabled()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                            .padding()
                            .glassEffect(in: .circle)
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "xmark")
//                    }
//                }
//            }
        }
    }
}

#Preview {
    let images = (1...5).map { index in
        ClubImage(
            clubId: UUID(),
            eventId: UUID(),
            type: .image,
            title: "Gallery Image \(index)",
            fileUrl: index % 2 == 0 ? "image1" : "image2",
            uploadedBy: UUID(),
            createdAt: Date()
        )
    }
    return FullScreenGalleryView(images: images, selectedIndex: .constant(0))
}
