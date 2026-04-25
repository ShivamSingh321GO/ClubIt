import SwiftUI

struct ClubFilesView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddSheet = false
    
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
                            FileCard(file: file)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    if appSession.currentRole == .clubLead {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                appSession.clubFileStore.deleteFile(file)
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
            AddClubFileView { newFile in
                var file = newFile
                file.clubId = appSession.clubStore.club.id
                file.uploadedBy = appSession.currentUser?.name ?? "Lead"
                appSession.clubFileStore.addFile(file)
            }
        }
    }
}

struct FileCard: View {
    let file: ClubFile
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: fileIcon(for: file.name))
                    .font(.title3)
                    .foregroundColor(.orange)
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
                
                Text(file.date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Action to download file
                
            }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private func fileIcon(for filename: String) -> String {
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
