//
//  AddActivityFormView.swift
//  ClubIt
//

import SwiftUI

struct AddActivityFormView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    
    @State private var type: ActivityType = .workshop
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var location: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Type", selection: $type) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time & Location") {
                    DatePicker("Date & Time", selection: $date)
                    
                    TextField("Location (Optional)", text: $location)
                }
            }
            .navigationTitle("New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("",systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("",systemImage: "checkmark") {
                        addActivity()
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
    }
   
    private func addActivity() {
        guard let user = appSession.currentUser else { return }
        
        let newActivity = Activity(id: UUID(), type: type,
            title: title,
            description: description,
            date: date,
            location: location.isEmpty ? nil : location,
            clubId: appSession.clubStore.club.id,
            postedBy: user.id,
            createdAt: Date()
        )
        
        withAnimation {
            appSession.activityStore.addActivity(newActivity)
        }
        dismiss()
    }
}

#Preview {
    AddActivityFormView()
        .environment(AppSession())
}
