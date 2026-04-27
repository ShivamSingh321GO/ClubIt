//
//  CreateAnnouncementView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//


import SwiftUI

struct CreateAnnouncementView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let onSave: (_ title: String, _ content: String, _ url: String, _ postedBy: UUID, _ clubId: UUID?) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var url = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    TextField("URL (Optional)", text: $url)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create an announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAnnouncement()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    private func saveAnnouncement() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a title."
            return
        }
        
        guard !trimmedContent.isEmpty else {
            errorMessage = "Please enter a description."
            return
        }
        
        guard let currentUser = appSession.currentUser else {
            errorMessage = "No logged in user found."
            return
        }
        
        onSave(
            trimmedTitle,
            trimmedContent,
            trimmedURL,
            currentUser.id,
            currentUser.clubId
        )
        
        dismiss()
    }
}

#Preview {
    CreateAnnouncementView { _, _, _, _, _ in }
        .environment(MockData.session(for: .clubLead))
}
