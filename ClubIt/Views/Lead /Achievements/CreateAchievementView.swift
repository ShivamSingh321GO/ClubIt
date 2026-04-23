//
//  CreateAchievementView.swift
//  ClubIt
//

import SwiftUI

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
                    .pickerStyle(.menu)
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
                        let newAchievement = Achievement(
                            clubId: appSession.clubStore.club.id,
                            title: title,
                            description: description,
                            type: selectedType,
                            createdAt: Date()
                        )
                        appSession.clubAchievementStore.addAchievement(newAchievement)
                        dismiss()
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
    return CreateAchievementView()
        .environment(session)
}
