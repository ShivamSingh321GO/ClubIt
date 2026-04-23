import SwiftUI

struct DraftBudgetItem: Identifiable {
    let id = UUID()
    var name: String = ""
    var price: String = ""
    var quantity: Int = 1
}

struct AddBudgetItemView: View {
    
    @Environment(\.dismiss) private var dismiss
    let onSave: ([DraftBudgetItem]) -> Void
    @State private var items: [DraftBudgetItem] = [DraftBudgetItem()]

    
    var body: some View {
        List {
            ForEach($items) { $item in
                Section {
                    HStack {
                        TextField("Name", text: $item.name)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Text("\(item.quantity)")
                                .foregroundStyle(.secondary)
                            
                            Stepper("", value: $item.quantity, in: 1...100)
                                .labelsHidden()
                        }
                    }
                    .padding(.vertical, 4)
                    
                    TextField("Price", text: $item.price)
                        .keyboardType(.decimalPad)
                        .padding(.vertical, 4)
                }
            }
            
            Section {
                Button {
                    items.append(DraftBudgetItem())
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Another Item")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onSave(items.filter { !$0.name.isEmpty })
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddBudgetItemView { _ in }
    }

}
