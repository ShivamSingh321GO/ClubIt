import SwiftUI
import ClubItShared
import UniformTypeIdentifiers

struct AddClubFileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedFileURL: URL?
    @State private var fileName = ""
    @State private var fileSize = ""
    @State private var selectedFileData: Data? = nil
    @State private var showingFileImporter = false
    @State private var errorMessage: String?
    
    var onSave: (ClubFile, Data) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("File Name", text: $name)
                        .font(.body)
                } header: {
                    Text("Display Name")
                }
                
                Section {
                    Button(action: { showingFileImporter = true }) {
                        HStack {
                            Label(selectedFileURL == nil ? "Select File from Device" : "Change File", systemImage: "doc.badge.plus")
                                .foregroundColor(.blue)
                            Spacer()
                            if selectedFileURL != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    if let _ = selectedFileURL {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("File: \(fileName)")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            Text("Size: \(fileSize)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("File Attachment")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveFile()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        handleSelectedFile(url)
                    }
                case .failure(let error):
                    errorMessage = "Error selecting file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleSelectedFile(_ url: URL) {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Failed to access file security scope."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
            fileName = resources.name ?? url.lastPathComponent
            
            if let size = resources.fileSize {
                fileSize = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            } else {
                fileSize = "Unknown size"
            }
            
            // Read raw data from the file to upload
            let fileData = try Data(contentsOf: url)
            selectedFileData = fileData
            selectedFileURL = url
            
            if name.isEmpty {
                name = fileName
            }
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
    
    private func saveFile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a display name."
            return
        }
        
        guard let data = selectedFileData, let url = selectedFileURL else {
            errorMessage = "Please select a file to upload."
            return
        }
        
        let newFile = ClubFile(
            id: UUID(),
            clubId: UUID(), // Placeholder, will be updated in onSave
            name: trimmedName,
            size: fileSize,
            uploadedBy: "Lead",
            fileURL: url.absoluteString, // Placeholder URL string, will be replaced with Supabase public URL in Store
            createdAt: Date()
        )
        
        onSave(newFile, data)
        dismiss()
    }
}

#Preview {
    AddClubFileView { _, _ in }
}
