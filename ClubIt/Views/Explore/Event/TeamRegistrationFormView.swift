import SwiftUI

struct TeamRegistrationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var fields: [RegistrationFormField]
    
    var body: some View {
        List {
            Section {
                Text("Create a custom registration form for your event. This form will be shown to participants when they register.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            ForEach($fields) { $field in
                FieldEditorView(field: $field) {
                    removeField(field.id)
                }
            }
            .onMove(perform: moveField)
            
            Section {
                Button {
                    addField()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Question")
                    }
                }
            }
        }
        .navigationTitle("Registration Form")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func addField() {
        let newField = RegistrationFormField(id: UUID(), label: "Untitled Question", type: .text)
        fields.append(newField)
    }
    
    private func removeField(_ id: UUID) {
        fields.removeAll { $0.id == id }
    }
    
    private func moveField(from source: IndexSet, to destination: Int) {
        fields.move(fromOffsets: source, toOffset: destination)
    }
}

struct FieldEditorView: View {
    @Binding var field: RegistrationFormField
    let onDelete: () -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Question", text: $field.label)
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    ForEach(FormFieldType.allCases, id: \.self) { type in
                        Button {
                            field.type = type
                            if type == .multipleChoice || type == .checkbox || type == .dropdown {
                                if field.options == nil {
                                    field.options = ["Option 1"]
                                }
                            } else {
                                field.options = nil
                            }
                        } label: {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: field.type.icon)
                        Text(field.type.rawValue)
                        Image(systemName: "chevron.up.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
            }
            
            if let options = field.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<options.count, id: \.self) { index in
                        HStack {
                            Image(systemName: field.type == .checkbox ? "square" : "circle")
                                .foregroundStyle(.secondary)
                            
                            TextField("Option \(index + 1)", text: Binding(
                                get: { field.options?[index] ?? "" },
                                set: { field.options?[index] = $0 }
                            ))
                            
                            if options.count > 1 {
                                Button {
                                    field.options?.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    
                    Button {
                        field.options?.append("Option \((field.options?.count ?? 0) + 1)")
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Option")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 24)
                }
            } else {
                Text(field.type == .text ? "Short answer text" : "Long answer text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
            }
            
            Divider()
            
            HStack {
                Toggle("Required", isOn: $field.isRequired)
                    .labelsHidden()
                Text("Required")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        TeamRegistrationFormView(fields: .constant([
            RegistrationFormField(id: UUID(), label: "What is your name?", type: .text),
            RegistrationFormField(id: UUID(), label: "Choose your shirt size", type: .multipleChoice, options: ["S", "M", "L", "XL"])
        ]))
    }
}
