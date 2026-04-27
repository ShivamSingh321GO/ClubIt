import SwiftUI

struct AddClubLinkView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var url = ""
    @State private var errorMessage: String?
    
    var onSave: (ClubLink) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(.body)
                } header: {
                    Text("Name")
                }
                
                Section {
                    TextField("URL", text: $url)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("URL")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Link")
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
                    Button(action: {
                        saveLink()
                    }) {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    private func saveLink() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name."
            return
        }
        
        guard !trimmedUrl.isEmpty else {
            errorMessage = "Please enter a URL."
            return
        }
        
        let newLink = ClubLink(
            id: UUID(),
            clubId: UUID(), // Placeholder, updated by caller
            name: trimmedName,
            url: trimmedUrl,
            uploadedBy: "Lead",
            createdAt: Date()
        )
        
        onSave(newLink)
        dismiss()
    }
}

#Preview {
    AddClubLinkView { _ in }
}
