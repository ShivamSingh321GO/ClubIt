import SwiftUI
import PhotosUI

struct AddImageSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var title: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var pickedImagesData: [Data] = []
    @State private var isUploading: Bool = false
    
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
                                .foregroundColor(.accentColor)
                            Text("Select Images")
                                .foregroundColor(.primary)
                            Spacer()
                            if !selectedItems.isEmpty {
                                Text("\(selectedItems.count)")
                                    .padding(6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(Circle())
                                    .font(.caption2.bold())
                                    .foregroundColor(.accentColor)
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
                    .disabled(isUploading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isUploading {
                        ProgressView()
                    } else {
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
        .disabled(isUploading)
    }
    
    private func saveSection() {
        guard !title.isEmpty && !pickedImagesData.isEmpty else { return }
        isUploading = true
        
        Task {
            do {
                let clubId = appSession.clubStore.club.id
                let userId = appSession.currentUser?.id ?? UUID()
                
                // Upload all picked images
                for data in pickedImagesData {
                    try await appSession.clubImageStore.addImage(
                        title: title,
                        imageData: data,
                        clubId: clubId,
                        uploadedBy: userId
                    )
                }
                
                await MainActor.run {
                    isUploading = false
                    dismiss()
                }
            } catch {
                print("DEBUG: Upload failed: \(error)")
                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}

#Preview {
    AddImageSectionView()
        .environment(AppSession())
}
