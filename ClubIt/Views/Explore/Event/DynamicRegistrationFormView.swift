import SwiftUI

struct DynamicRegistrationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let event: Event
    @State private var responses: [UUID: String] = [:]
    @State private var checkboxResponses: [UUID: Set<String>] = [:]
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Please fill out the details required for \(event.name).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let fields = event.registrationForm {
                    ForEach(fields) { field in
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(field.label)
                                        .font(.headline)
                                    if field.isRequired {
                                        Text("*")
                                            .foregroundStyle(.red)
                                    }
                                }
                                
                                renderField(field)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        submitForm()
                    } label: {
                        Text("Submit Registration")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderField(_ field: RegistrationFormField) -> some View {
        switch field.type {
        case .text:
            TextField("Your answer", text: Binding(
                get: { responses[field.id] ?? "" },
                set: { responses[field.id] = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            
        case .paragraph:
            TextField("Your answer", text: Binding(
                get: { responses[field.id] ?? "" },
                set: { responses[field.id] = $0 }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(3...5)
            
        case .multipleChoice:
            if let options = field.options {
                Picker(field.label, selection: Binding(
                    get: { responses[field.id] ?? "" },
                    set: { responses[field.id] = $0 }
                )) {
                    Text("Select an option").tag("")
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
        case .checkbox:
            if let options = field.options {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            var current = checkboxResponses[field.id] ?? []
                            if current.contains(option) {
                                current.remove(option)
                            } else {
                                current.insert(option)
                            }
                            checkboxResponses[field.id] = current
                        } label: {
                            HStack {
                                Image(systemName: (checkboxResponses[field.id]?.contains(option) ?? false) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle((checkboxResponses[field.id]?.contains(option) ?? false) ? .blue : .secondary)
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
        case .dropdown:
            if let options = field.options {
                Picker(field.label, selection: Binding(
                    get: { responses[field.id] ?? "" },
                    set: { responses[field.id] = $0 }
                )) {
                    Text("Choose").tag("")
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }
    
    private func submitForm() {
        // Validate required fields
        if let fields = event.registrationForm {
            for field in fields where field.isRequired {
                if field.type == .checkbox {
                    if checkboxResponses[field.id]?.isEmpty ?? true {
                        errorMessage = "Please answer all required questions."
                        return
                    }
                } else {
                    if responses[field.id]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                        errorMessage = "Please answer all required questions."
                        return
                    }
                }
            }
        }
        
        // Complete registration
        appSession.registerForEvent(id: event.id)
        dismiss()
    }
}

#Preview {
    DynamicRegistrationFormView(event: Event(id: UUID(), name: "Hackathon 2026",
        title: "Hackathon 2026",
        description: "Join us for 24 hours of coding!",
        startDate: Date(),
        endDate: Date(),
        startTime: Date(),
        endTime: Date(),
        numberOfVolunteers: 0,
        numberOfRegistrations: 0,
        maxParticipants: 100,
        registrationType: .team,
        location: "Hall A",
        clubId: UUID(),
        createdBy: UUID(),
        category: .technical,
        status: .upcoming,
        registrationDeadline: Date(),
        registrationForm: [
            RegistrationFormField(id: UUID(), label: "What is your team name?", type: .text),
            RegistrationFormField(id: UUID(), label: "Experience level", type: .multipleChoice, options: ["Beginner", "Intermediate", "Advanced"]),
            RegistrationFormField(id: UUID(), label: "Technologies you use", type: .checkbox, options: ["Swift", "Python", "React", "Node.js"])
        ],
        createdAt: Date()
    ))
    .environment(MockData.session(for: .student))
}
