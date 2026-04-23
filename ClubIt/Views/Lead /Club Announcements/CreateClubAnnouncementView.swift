//
//  CreateClubAnnouncementView.swift
//  ClubIt
//

import SwiftUI

struct CreateClubAnnouncementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let onSave: (String, String, String) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var url = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title and Description Card
                    VStack(spacing: 0) {
                        TextField("Title", text: $title)
                            .padding()
                            .foregroundColor(.primary)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        TextField("Description", text: $content, axis: .vertical)
                            .lineLimit(5...10)
                            .padding()
                            .foregroundColor(.primary)
                    }
                    .background(Color.cardsBackground)
                    .cornerRadius(24)
                    
                    // URL Card
                    TextField("URL (Optional)", text: $url)
                        .padding()
                        .background(Color.cardsBackground)
                        .cornerRadius(24)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .foregroundColor(.primary)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.f2Background.ignoresSafeArea())
            .navigationTitle("Create announcement")
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
        
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a title."
            return
        }
        
        guard !trimmedContent.isEmpty else {
            errorMessage = "Please enter a description."
            return
        }
        
        onSave(trimmedTitle, trimmedContent, url.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

#Preview {
    CreateClubAnnouncementView { _, _, _ in }
        .environment(AppSession())
}
