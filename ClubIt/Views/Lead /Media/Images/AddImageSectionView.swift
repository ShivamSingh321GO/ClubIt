import SwiftUI
import PhotosUI

struct AddImageSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var title: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var pickedImagesData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section() {
                    TextField("Enter Section Title", text: $title)
                        .font(.body)
                }
                
                Section(header: Text("IMAGES")) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 15, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(.goldenBrown)
                            Text("Select Images")
                                .foregroundColor(.primary)
                            Spacer()
                            if !selectedItems.isEmpty {
                                Text("\(selectedItems.count)")
                                    .padding(6)
                                    .background(Color.goldenBrown.opacity(0.1))
                                    .clipShape(Circle())
                                    .font(.caption2.bold())
                                    .foregroundColor(.goldenBrown)
                            }
                        }
                    }
                    
                    if pickedImagesData.isEmpty {
                        Text(selectedItems.isEmpty ? "No images selected yet" : "Loading images...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<pickedImagesData.count, id: \.self) { index in
                                    if let uiImage = UIImage(data: pickedImagesData[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                            .clipped()
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .task(id: selectedItems) {
                var loadedData: [Data] = []
                for item in selectedItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loadedData.append(data)
                    }
                }
                pickedImagesData = loadedData
            }
            .navigationTitle("New Image Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveSection()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.isEmpty || pickedImagesData.isEmpty)
                }
            }
        }
    }
    
    private func saveSection() {
        let mediaItems = pickedImagesData.map { data in
            ClubImage(
                clubId: appSession.clubStore.club.id,
                eventId: nil,
                type: .image,
                title: title,
                fileUrl: "",
                imageData: data,
                uploadedBy: appSession.currentUser?.id ?? UUID(),
                createdAt: Date()
            )
        }
        
        let newSection = ClubImageSection(
            title: title,
            images: mediaItems,
            remainingCount: max(0, mediaItems.count - 6)
        )
        
        appSession.clubImageStore.addSection(newSection)
        dismiss()
    }
}

#Preview {
    AddImageSectionView()
        .environment(AppSession())
}
