import SwiftUI

struct ClubFilesView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddSheet = false
    @State private var downloadingFileIds: Set<UUID> = []
    
    var body: some View {
        let filteredFiles = appSession.clubFileStore.files.filter { 
            $0.clubId == appSession.clubStore.club.id 
        }
        
        Group {
            if filteredFiles.isEmpty {
                ContentUnavailableView(
                    "No Files Yet",
                    systemImage: "doc.text",
                    description: Text("Only members of this club can see these files.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(filteredFiles) { file in
                            FileCard(
                                file: file,
                                isDownloading: downloadingFileIds.contains(file.id),
                                onDownload: {
                                    downloadAndShareFile(file)
                                }
                            )
                            .contentShape(Rectangle())
                            .contextMenu {
                                if appSession.currentRole == .clubLead {
                                    Button(role: .destructive) {
                                        Task {
                                            try? await appSession.clubFileStore.deleteFile(file)
                                        }
                                    } label: {
                                        Label("Delete File", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    try? await appSession.clubFileStore.fetchFiles(clubId: appSession.clubStore.club.id)
                }
            }
        }
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appSession.currentRole == .clubLead {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddClubFileView { newFile, fileData in
                var file = newFile
                file.clubId = appSession.clubStore.club.id
                file.uploadedBy = appSession.currentUser?.name ?? "Lead"
                Task {
                    try? await appSession.clubFileStore.addFile(file, fileData: fileData)
                }
            }
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
    
    private func downloadAndShareFile(_ file: ClubFile) {
        guard let fileUrlString = file.fileURL, let url = URL(string: fileUrlString) else { return }
        
        downloadingFileIds.insert(file.id)
        
        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                
                // Save the file with the original display name
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                
                // Get extension from URL or name
                let originalExtension = url.pathExtension.isEmpty ? "bin" : url.pathExtension
                let finalFilename = file.name.hasSuffix(".\(originalExtension)") ? file.name : "\(file.name).\(originalExtension)"
                let destinationURL = documentsURL.appendingPathComponent(finalFilename)
                
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try? fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                
                await MainActor.run {
                    downloadingFileIds.remove(file.id)
                    
                    let activityVC = UIActivityViewController(activityItems: [destinationURL], applicationActivities: nil)
                    if let topVC = getTopViewController() {
                        if let popoverController = activityVC.popoverPresentationController {
                            popoverController.sourceView = topVC.view
                            popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                            popoverController.permittedArrowDirections = []
                        }
                        topVC.present(activityVC, animated: true)
                    }
                }
            } catch {
                print("DEBUG: Failed to download/save file: \(error)")
                await MainActor.run {
                    downloadingFileIds.remove(file.id)
                }
            }
        }
    }
}

struct FileCard: View {
    let file: ClubFile
    let isDownloading: Bool
    let onDownload: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: fileIcon(for: file))
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(file.size)
                    Text("•")
                    Text(file.uploadedBy)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                
                Text(file.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDownload) {
                Group {
                    if isDownloading {
                        ProgressView()
                            .tint(.primary)
                            .padding(8)
                    } else {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(8)
                    }
                }
                .background(.thinMaterial)
                .clipShape(Circle())
            }
            .disabled(isDownloading)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private func fileIcon(for file: ClubFile) -> String {
        let source = file.fileURL ?? file.name
        let filename = URL(string: source)?.lastPathComponent ?? source
        let ext = filename.lowercased().split(separator: ".").last ?? ""
        
        switch ext {
        case "pdf": return "richtext.page.fill"
        case "doc", "docx": return "text.document.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "document.on.document.fill"
        case "jpg", "jpeg", "png", "heic": return "photo.fill"
        default: return "doc.text.fill"
        }
    }
}

#Preview {
    NavigationStack {
        ClubFilesView()
            .environment(AppSession())
    }
}
