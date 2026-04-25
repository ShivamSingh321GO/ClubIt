import SwiftUI

struct DraftResourceItem: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var price: String = ""
    var quantity: Int = 1
    var vendorName: String = ""
}

struct AddResourceItemView: View {
    
    @Environment(\.dismiss) private var dismiss
    let onSave: ([DraftResourceItem], [DraftResourceItem]) -> Void
    
    @State private var selectedTab = 0
    @State private var universityItems: [DraftResourceItem]
    @State private var rentalItems: [DraftResourceItem]

    init(initialUniversityItems: [DraftResourceItem] = [], initialRentalItems: [DraftResourceItem] = [], onSave: @escaping ([DraftResourceItem], [DraftResourceItem]) -> Void) {
        self.onSave = onSave
        _universityItems = State(initialValue: initialUniversityItems.isEmpty ? [DraftResourceItem()] : initialUniversityItems)
        _rentalItems = State(initialValue: initialRentalItems.isEmpty ? [DraftResourceItem()] : initialRentalItems)
    }

    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Within university").tag(0)
                Text("External rental").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                if selectedTab == 0 {
                    ForEach($universityItems) { $item in
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
                        }
                    }
                    
                    Section {
                        Button {
                            universityItems.append(DraftResourceItem())
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
                } else {
                    ForEach($rentalItems) { $item in
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
                            
                            TextField("Vendor Name", text: $item.vendorName)
                                .padding(.vertical, 4)
                        }
                    }
                    
                    Section {
                        Button {
                            rentalItems.append(DraftResourceItem())
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
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Resources Items")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onSave(universityItems.filter { !$0.name.isEmpty }, rentalItems.filter { !$0.name.isEmpty })
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }

    }
}

#Preview {
    NavigationStack {
        AddResourceItemView { _, _ in }
    }

}
