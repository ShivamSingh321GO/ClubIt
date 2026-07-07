import SwiftUI
import ClubItShared

enum FileTypeFilter: String, CaseIterable, Identifiable {
    case all = "All Types"
    case pdf = "PDFs"
    case word = "Word Docs"
    case excel = "Spreadsheets"
    case images = "Images"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "doc.text.magnifyingglass"
        case .pdf: return "richtext.page.fill"
        case .word: return "text.document.fill"
        case .excel: return "tablecells.fill"
        case .images: return "photo.fill"
        case .other: return "doc.fill"
        }
    }
}

enum FileDateFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    
    var id: String { self.rawValue }
}

struct SubgroupFilesView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddSheet = false
    @State private var downloadingFileIds: Set<UUID> = []
    
    @State private var searchText = ""
    @State private var selectedTypeFilter: FileTypeFilter = .all
    @State private var selectedDateFilter: FileDateFilter = .all
    
    var body: some View {
        let filteredFiles = appSession.subgroupFileStore.files.filter { file in
            // 1. Subgroup match
            guard file.subgroupId == appSession.subgroupStore.subgroup.id else { return false }
            
            // 2. Search Text match
            if !searchText.isEmpty {
                if !file.name.localizedCaseInsensitiveContains(searchText) &&
                   !file.uploadedBy.localizedCaseInsensitiveContains(searchText) {
                    return false
                }
            }
            
            // 3. File Type filter match
            let ext = file.name.lowercased().split(separator: ".").last ?? ""
            switch selectedTypeFilter {
            case .all:
                break
            case .pdf:
                if ext != "pdf" { return false }
            case .word:
                if ext != "doc" && ext != "docx" { return false }
            case .excel:
                if ext != "xls" && ext != "xlsx" && ext != "csv" { return false }
            case .images:
                if ext != "jpg" && ext != "jpeg" && ext != "png" && ext != "heic" { return false }
            case .other:
                let knownExts: Set<String> = ["pdf", "doc", "docx", "xls", "xlsx", "csv", "jpg", "jpeg", "png", "heic"]
                if knownExts.contains(String(ext)) { return false }
            }
            
            // 4. Date filter match
            let calendar = Calendar.current
            switch selectedDateFilter {
            case .all:
                break
            case .today:
                if !calendar.isDateInToday(file.createdAt) { return false }
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
                if file.createdAt < weekAgo { return false }
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) else { return false }
                if file.createdAt < monthAgo { return false }
            }
            
            return true
        }
        
        let totalFilesCount = appSession.subgroupFileStore.files.filter {
            $0.subgroupId == appSession.subgroupStore.subgroup.id
        }.count
        
        VStack(spacing: 0) {
            // Filter Bar
            if totalFilesCount > 0 {
                HStack(spacing: 12) {
                    // Type Menu Filter
                    Menu {
                        Picker("Type", selection: $selectedTypeFilter) {
                            ForEach(FileTypeFilter.allCases) { filter in
                                Label(filter.rawValue, systemImage: filter.icon).tag(filter)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedTypeFilter.icon)
                            Text(selectedTypeFilter.rawValue)
                            Image(systemName: "chevron.down").font(.caption)
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    // Date Menu Filter
                    Menu {
                        Picker("Date Uploaded", selection: $selectedDateFilter) {
                            ForEach(FileDateFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                            Text(selectedDateFilter.rawValue)
                            Image(systemName: "chevron.down").font(.caption)
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            
            Group {
                if totalFilesCount == 0 {
                    ContentUnavailableView(
                        "No Files Yet",
                        systemImage: "doc.text",
                        description: Text("Only members of this subgroup can see these files.")
                    )
                } else if filteredFiles.isEmpty {
                    ContentUnavailableView(
                        "No Matches Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try adjusting your search query or filters.")
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
                                    if appSession.currentRole == .subGroupLead {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await appSession.subgroupFileStore.deleteFile(file)
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
                        try? await appSession.subgroupFileStore.fetchFiles(subgroupId: appSession.subgroupStore.subgroup.id)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search files...")
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appSession.currentRole == .subGroupLead {
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
            AddSubgroupFileView { newFile, fileData in
                var file = newFile
                file.subgroupId = appSession.subgroupStore.subgroup.id
                file.uploadedBy = appSession.currentUser?.name ?? "Lead"
                Task {
                    try? await appSession.subgroupFileStore.addFile(file, fileData: fileData)
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
    
    private func downloadAndShareFile(_ file: SubgroupFile) {
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
    let file: SubgroupFile
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
    
    private func fileIcon(for file: SubgroupFile) -> String {
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
        SubgroupFilesView()
            .environment(AppSession())
    }
}
