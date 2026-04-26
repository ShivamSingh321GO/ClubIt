import SwiftUI
import PhotosUI

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let event: Event
    let onSave: (Event) -> Void
    
    @State private var eventName: String
    @State private var selectedCategory: EventCategory
    @State private var eventDescription: String
    @State private var agenda: String
    
    @State private var registrationType: RegistrationType
    @State private var budgetItems: [DraftBudgetItem] = []
    @State private var universityResources: [DraftResourceItem] = []
    @State private var rentalResources: [DraftResourceItem] = []
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var startDate: Date
    @State private var endDate: Date
    
    @State private var venue: String
    @State private var participants: String
    
    @State private var isShowingAddBudgetItems = false
    @State private var isShowingAddResourcesItems = false
    @State private var isShowingBudgetSummary = false
    @State private var isShowingResourceSummary = false
    
    @State private var errorMessage: String?
    @State private var customFormFields: [RegistrationFormField] = []

    init(event: Event, onSave: @escaping (Event) -> Void) {
        self.event = event
        self.onSave = onSave
        
        _eventName = State(initialValue: event.name)
        _selectedCategory = State(initialValue: event.category)
        _eventDescription = State(initialValue: event.description)
        _agenda = State(initialValue: event.agenda ?? "")
        _registrationType = State(initialValue: event.registrationType ?? .individual)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _venue = State(initialValue: event.location)
        _participants = State(initialValue: "\(event.maxParticipants)")
        _imageData = State(initialValue: event.imageData)
        _customFormFields = State(initialValue: event.registrationForm ?? [])
    }
    
    // Venues are now fetched from VenueStore
    
    var body: some View {
        Form {
            Section {
                TextField("Event Name", text: $eventName)
                    .textInputAutocapitalization(.words)
                
                Picker("Event Category", selection: $selectedCategory) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Basic Info")
            }
            
            Section {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 15) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 60, height: 60)
                            
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Event Image")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Add a cover image for the event")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(imageData == nil ? "Choose Photo" : "Change Photo")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Event Image")
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            
            Section {
                Picker("Type", selection: $registrationType) {
                    Text("Individual").tag(RegistrationType.individual)
                    Text("Team").tag(RegistrationType.team)
                }
                .pickerStyle(.segmented)
                
                if registrationType == .team {
                    NavigationLink {
                        TeamRegistrationFormView(fields: $customFormFields)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.purple)
                            Text("Setup Team Registration Form")
                                .font(.subheadline)
                        }
                    }
                }
            } header: {
                Text("Registration")
            }
            
            Section {
                TextField("Event Description", text: $eventDescription, axis: .vertical)
                    .frame(minHeight: 100)
                    .lineLimit(2...4)
                
                TextField("Agenda (Optional)", text: $agenda, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Details")
            }
            
            Section {
                DatePicker("Starts", selection: $startDate)
                DatePicker("Ends", selection: $endDate)
            } header: {
                Text("Date & Time")
            }
            
            Section {
                let sortedVenues = appSession.venueStore.allVenues.sorted { $0.name < $1.name }
                let conflictingEvents = appSession.eventStore.events.filter { e in
                    e.id != event.id && // Don't check against self
                    e.status != .cancelled && 
                    e.status != .completed && 
                    e.status != .pastEvent &&
                    (startDate < e.endDate) && (e.startDate < endDate)
                }
                
                Picker("Location", selection: $venue) {
                    ForEach(sortedVenues) { v in
                        let isBooked = conflictingEvents.contains { $0.location == v.name }
                        HStack {
                            Text(v.name)
                            if isBooked {
                                Spacer()
                                Text("Unavailable")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .tag(v.name)
                        .disabled(isBooked)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Venue")
            }
            
            Section {
                Button {
                    isShowingAddBudgetItems = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Manage Budget Items")
                    }
                }
                .foregroundStyle(.primary)
                
                if !budgetItems.isEmpty {
                    let total = budgetItems.reduce(0) { $0 + (Double($1.price) ?? 0) * Double($1.quantity) }
                    Button {
                        isShowingBudgetSummary = true
                    } label: {
                        HStack {
                            Text("\(budgetItems.count) items • Total: ₹\(Int(total))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Budget")
            }
            
            Section {
                Button {
                    isShowingAddResourcesItems = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Manage Resources")
                    }
                }
                .foregroundStyle(.primary)
                
                if !universityResources.isEmpty || !rentalResources.isEmpty {
                    Button {
                        isShowingResourceSummary = true
                    } label: {
                        HStack {
                            Text("\(universityResources.count + rentalResources.count) items added")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Resources")
            }

            Section {
                TextField("Expected Participants", text: $participants)
                    .keyboardType(.numberPad)
            } header: {
                Text("Participation & Support")
            }
            
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            
            Section {
                let isVenueBooked = appSession.eventStore.events.contains { e in
                    e.id != event.id && 
                    e.status != .cancelled && e.status != .completed && e.status != .pastEvent &&
                    e.location == venue &&
                    (startDate < e.endDate) && (e.startDate < endDate)
                }
                
                if isVenueBooked {
                    Text("Selected venue is unavailable for this time slot")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            loadExistingItems()
        }
        .navigationTitle("Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                let isVenueBooked = appSession.eventStore.events.contains { e in
                    e.id != event.id && // Don't check against self
                    e.status != .cancelled && e.status != .completed && e.status != .pastEvent &&
                    e.location == venue &&
                    (startDate < e.endDate) && (e.startDate < endDate)
                }

                Button("Update") {
                    updateEvent()
                }
                .fontWeight(.bold)
                .disabled(isVenueBooked)
            }
        }

        .sheet(isPresented: $isShowingAddBudgetItems) {
            NavigationStack {
                AddBudgetItemView(initialItems: budgetItems) { items in
                    self.budgetItems = items
                }
            }
        }
        .sheet(isPresented: $isShowingAddResourcesItems) {
            NavigationStack {
                AddResourceItemView(initialUniversityItems: universityResources, initialRentalItems: rentalResources) { uni, rent in
                    self.universityResources = uni
                    self.rentalResources = rent
                }
            }
        }
        .sheet(isPresented: $isShowingBudgetSummary) {
            BudgetSummarySheet(items: budgetItems)
        }
        .sheet(isPresented: $isShowingResourceSummary) {
            ResourceSummarySheet(universityItems: universityResources, rentalItems: rentalResources)
        }
    }
    
    private func loadExistingItems() {
        // Load Budget Items
        let existingBudgets = appSession.approvalStore.budgets.filter { $0.eventId == event.id }
        budgetItems = existingBudgets.map { budget in
            DraftBudgetItem(id: budget.id, name: budget.itemName, price: "\(Int(budget.unitPrice))", quantity: budget.quantity)
        }
        
        // Load Resources
        let existingResources = appSession.approvalStore.resources.filter { $0.eventId == event.id }
        universityResources = existingResources.filter { $0.type == .university }.map { res in
            DraftResourceItem(id: res.id, name: res.name, quantity: res.quantity)
        }
        rentalResources = existingResources.filter { $0.type == .external }.map { res in
            DraftResourceItem(id: res.id, name: res.name, price: "\(Int((res.cost ?? 0) / Double(res.quantity)))", quantity: res.quantity, vendorName: res.vendorName ?? "")
        }
    }
    
    private func updateEvent() {
        // 1. Validate
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedDescription.isEmpty else {
            errorMessage = "Please fill all required fields."
            return
        }
        
        // 2. Update Event Model in Store
        var updatedEvent = event
        updatedEvent.name = trimmedName
        updatedEvent.title = trimmedName
        updatedEvent.description = trimmedDescription
        updatedEvent.category = selectedCategory
        updatedEvent.agenda = agenda
        updatedEvent.registrationType = registrationType
        updatedEvent.startDate = startDate
        updatedEvent.endDate = endDate
        updatedEvent.location = venue
        updatedEvent.numberOfVolunteers = 0
        updatedEvent.maxParticipants = Int(participants) ?? 0
        updatedEvent.imageData = imageData
        updatedEvent.registrationForm = customFormFields
        
        appSession.eventStore.updateEvent(updatedEvent)
        
        // 3. Conditional Re-submission Logic
        let club = appSession.clubStore.allClubs.first(where: { $0.id == updatedEvent.clubId })
        let facultyId = club?.facultyId ?? UUID()
        let currentUser = appSession.currentUser!

        // Venue Approval re-submission
        if let venueApproval = appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .venue }) {
            if venueApproval.status == .rejected || event.location != venue {
                appSession.approvalStore.updateApprovalStatus(id: venueApproval.id, status: .pending)
                appSession.approvalStore.addRemarkToApproval(id: venueApproval.id, remark: Remark(id: UUID(), text: "Venue details updated: \(venue). Resubmitted for approval.", authorId: currentUser.id, createdAt: Date()))
            }
        }

        // Budget collection status check
        if let budgetApproval = appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .budget }) {
            let hasChanges = budgetItems.contains { draft in
                if let existing = appSession.approvalStore.budgets.first(where: { $0.id == draft.id }) {
                    let wasRejected = existing.status == .rejected
                    let dataChanged = existing.itemName != draft.name || 
                                     existing.unitPrice != (Double(draft.price) ?? 0) || 
                                     existing.quantity != draft.quantity
                    return wasRejected || dataChanged
                }
                return true // New item
            }
            if hasChanges {
                appSession.approvalStore.updateApprovalStatus(id: budgetApproval.id, status: .pending)
                appSession.approvalStore.addRemarkToApproval(id: budgetApproval.id, remark: Remark(id: UUID(), text: "Budget updated/items added. Resubmitted.", authorId: currentUser.id, createdAt: Date()))
            }
        }

        // Budget Items individual updates
        for draft in budgetItems {
            if let existing = appSession.approvalStore.budgets.first(where: { $0.id == draft.id }) {
                var updated = existing
                let dataChanged = updated.itemName != draft.name || 
                                 updated.unitPrice != (Double(draft.price) ?? 0) || 
                                 updated.quantity != draft.quantity
                
                updated.itemName = draft.name
                updated.unitPrice = Double(draft.price) ?? 0
                updated.quantity = draft.quantity
                
                if updated.status == .rejected || dataChanged {
                    updated.status = .pending
                    appSession.approvalStore.updateBudget(updated)
                } else {
                    appSession.approvalStore.updateBudget(updated)
                }
            } else {
                let newBudget = Budget(id: UUID(),
                    eventId: event.id,
                    itemName: draft.name,
                    unitPrice: Double(draft.price) ?? 0,
                    quantity: draft.quantity,
                    status: .pending,
                    addedBy: currentUser.id,
                    remarks: [],
                    createdAt: Date()
                )
                appSession.approvalStore.addBudget(newBudget)
            }
        }

        // Resource collection status check
        if let resourceApproval = appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .resource }) {
            let allDraftResources = universityResources + rentalResources
            let hasChanges = allDraftResources.contains { draft in
                if let existing = appSession.approvalStore.resources.first(where: { $0.id == draft.id }) {
                    let wasRejected = existing.status == .rejected
                    let dataChanged = existing.name != draft.name || existing.quantity != draft.quantity || (existing.vendorName != draft.vendorName && existing.type == .external)
                    return wasRejected || dataChanged
                }
                return true // New item
            }
            if hasChanges {
                appSession.approvalStore.updateApprovalStatus(id: resourceApproval.id, status: .pending)
                appSession.approvalStore.addRemarkToApproval(id: resourceApproval.id, remark: Remark(id: UUID(), text: "Resources updated/added. Resubmitted.", authorId: currentUser.id, createdAt: Date()))
            }
        }

        // Resources individual updates
        for draft in universityResources {
            if let existing = appSession.approvalStore.resources.first(where: { $0.id == draft.id }) {
                var updated = existing
                let dataChanged = updated.name != draft.name || updated.quantity != draft.quantity
                
                updated.name = draft.name
                updated.quantity = draft.quantity
                
                if updated.status == .rejected || dataChanged {
                    updated.status = .pending
                    appSession.approvalStore.updateResource(updated)
                } else {
                    appSession.approvalStore.updateResource(updated)
                }
            } else {
                let newRes = Resource(
                    id: UUID(),
                    eventId: event.id,
                    name: draft.name,
                    quantity: draft.quantity,
                    type: .university,
                    status: .pending,
                    addedBy: currentUser.id,
                    remarks: [],
                    createdAt: Date()
                )
                appSession.approvalStore.addResource(newRes)
            }
        }

        for draft in rentalResources {
            if let existing = appSession.approvalStore.resources.first(where: { $0.id == draft.id }) {
                var updated = existing
                let dataChanged = updated.name != draft.name || 
                                 updated.quantity != draft.quantity || 
                                 updated.cost != ((Double(draft.price) ?? 0) * Double(draft.quantity)) ||
                                 updated.vendorName != draft.vendorName
                
                updated.name = draft.name
                updated.quantity = draft.quantity
                updated.cost = (Double(draft.price) ?? 0) * Double(draft.quantity)
                updated.vendorName = draft.vendorName
                
                if updated.status == .rejected || dataChanged {
                    updated.status = .pending
                    appSession.approvalStore.updateResource(updated)
                } else {
                    appSession.approvalStore.updateResource(updated)
                }
            } else {
                let newRes = Resource(
                    id: UUID(),
                    eventId: event.id,
                    name: draft.name,
                    quantity: draft.quantity,
                    type: .external,
                    status: .pending,
                    cost: (Double(draft.price) ?? 0) * Double(draft.quantity),
                    vendorName: draft.vendorName,
                    addedBy: currentUser.id,
                    remarks: [],
                    createdAt: Date()
                )
                appSession.approvalStore.addResource(newRes)
            }
        }

        onSave(updatedEvent)
        dismiss()
    }
}
