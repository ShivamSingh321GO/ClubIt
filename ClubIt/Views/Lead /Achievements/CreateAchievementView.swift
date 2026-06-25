//
//  CreateAchievementView.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct CreateAchievementView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: AchievementType = .award
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Achievement Type", selection: $selectedType) {
                        ForEach(AchievementType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    
                }
                
                Section() {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Create Achievement")
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
                        let newAchievement = Achievement(id: UUID(), clubId: appSession.clubStore.club.id,
                            title: title,
                            description: description,
                            type: selectedType,
                            createdAt: Date()
                        )
                        Task {
                            do {
                                try await appSession.clubAchievementStore.addAchievement(newAchievement)
                                await MainActor.run {
                                    dismiss()
                                }
                            } catch {
                                print("DEBUG ERROR: Failed to add achievement: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
    }
}

#Preview {
    let session = AppSession()
    CreateAchievementView()
        .environment(session)
}
