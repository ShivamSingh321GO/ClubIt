//
//  CreateEventView.swift
//  ClubIt
//
//  Created by Ansh Srivastava on 3/20/26.
//


import SwiftUI
import PhotosUI


struct CreateNewEventView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let onSave: (Event) -> Void
    
    @State private var eventName = ""
    @State private var selectedCategory: EventCategory = .workshop
    @State private var eventDescription = ""
    @State private var agenda = ""
    
    @State private var registrationType: RegistrationType = .individual
    @State private var budgetItems: [DraftBudgetItem] = []
    @State private var universityResources: [DraftResourceItem] = []
    @State private var rentalResources: [DraftResourceItem] = []
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    
    @State private var venue = "New Auditorium"
    @State private var participants = ""
    
    @State private var isShowingAddBudgetItems = false
    @State private var isShowingAddResourcesItems = false
    @State private var isShowingBudgetSummary = false
    @State private var isShowingResourceSummary = false
    
    @State private var errorMessage: String?
    @State private var customFormFields: [RegistrationFormField] = []


    
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
                    Text("Individual")
                        .tag(RegistrationType.individual)
                    Text("Team")
                        .tag(RegistrationType.team)
                }
                .pickerStyle(.menu)
                
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
                DatePicker("Starts", selection: $startDate, in: Date()...)
                DatePicker("Ends", selection: $endDate, in: startDate...)
            } header: {
                Text("Date & Time")
            }
            
            Section {
                let sortedVenues = appSession.venueStore.allVenues.sorted { $0.name < $1.name }
                let conflictingEvents = appSession.eventStore.events.filter { event in
                    guard event.status != .cancelled && event.status != .completed && event.status != .pastEvent else { return false }
                    return (startDate < event.endDate) && (event.startDate < endDate)
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
                .pickerStyle(.navigationLink)
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
                        Text("Add Budget Items")
                    }
                }
                .foregroundStyle(.primary)
                
                if !budgetItems.isEmpty {
                    let total = budgetItems.reduce(0) { $0 + (Double($1.price) ?? 0) * Double($1.quantity) }
                    Button {
                        isShowingBudgetSummary = true
                    } label: {
                        HStack {
                            Text("\(budgetItems.count) \(budgetItems.count == 1 ? "item" : "items") added • Estimated Budget: ₹\(Int(total))")
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
                        Text(universityResources.isEmpty && rentalResources.isEmpty ? "Add Resources Items" : "\(universityResources.count + rentalResources.count) Items Added")
                    }
                }
                .foregroundStyle(.primary)
                
                if !universityResources.isEmpty || !rentalResources.isEmpty {
                    Button {
                        isShowingResourceSummary = true
                    } label: {
                        HStack {
                            Text("\(universityResources.count + rentalResources.count) \( (universityResources.count + rentalResources.count) == 1 ? "item" : "items") added")
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
                        .font(.caption)
                }
            }
            
            Section {
                let isVenueBooked = appSession.eventStore.events.contains { e in
                    e.status != .cancelled && e.status != .completed && e.status != .pastEvent &&
                    e.location == venue &&
                    (startDate < e.endDate) && (e.startDate < endDate)
                }
                
                Button {
                    saveEvent()
                } label: {
                    Text("Send Approval")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isVenueBooked)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                if isVenueBooked {
                    Text("Selected venue is unavailable for this time slot")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Create an Event")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func saveEvent() {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter an event name."
            return
        }
        
        guard !trimmedDescription.isEmpty else {
            errorMessage = "Please enter an event description."
            return
        }
        
        guard endDate >= startDate else {
            errorMessage = "End date must be after start date."
            return
        }
        
        guard let currentUser = appSession.currentUser else {
            errorMessage = "No logged in user found."
            return
        }
        
        let newEvent = Event(id: UUID(), name: trimmedName,
            title: trimmedName,
            description: trimmedDescription,
            startDate: startDate,
            endDate: endDate,
            startTime: startDate,
            endTime: endDate,
            numberOfVolunteers: 0,
            numberOfRegistrations: 0,
            maxParticipants: Int(participants) ?? 0,
            registrationType: registrationType,
            location: venue,
            clubId: currentUser.clubId ?? UUID(),
            createdBy: currentUser.id,
            category: selectedCategory,
            status: .pending,
            registrationDeadline: Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate,
            bannerImage: nil,
            imageData: imageData,
            agenda: agenda,
            registrationForm: customFormFields,
            createdAt: Date()
        )

        let club = appSession.clubStore.allClubs.first(where: { $0.id == newEvent.clubId })
        let facultyId = club?.facultyId ?? UUID()

        
        // Save Budget Items
        for item in budgetItems {
            let price = Double(item.price) ?? 0
            let budget = Budget(
                id: UUID(),
                eventId: newEvent.id,
                itemName: item.name,
                unitPrice: price,
                quantity: item.quantity,
                status: .pending,
                addedBy: currentUser.id,
                remarks: [],
                createdAt: Date()
            )
            appSession.approvalStore.addBudget(budget)
        }
        
        // Save Resource Items
        for item in universityResources {
            let resource = Resource(id: UUID(), 
                eventId: newEvent.id,
                name: item.name,
                quantity: item.quantity,
                type: .university,
                status: .pending,
                addedBy: currentUser.id,
                remarks: [],
                createdAt: Date()
            )
            appSession.approvalStore.addResource(resource)
        }
        
        for item in rentalResources {
            let price = Double(item.price) ?? 0
            let resource = Resource(id: UUID(), 
                eventId: newEvent.id,
                name: item.name,
                quantity: item.quantity,
                type: .external,
                status: .pending,
                cost: price * Double(item.quantity),
                vendorName: item.vendorName,
                addedBy: currentUser.id,
                remarks: [],
                createdAt: Date()
            )
            appSession.approvalStore.addResource(resource)
        }

        // Generate Approval Summaries for Faculty
        let eventApproval = Approval(
            id: UUID(),
            type: .event,
            senderId: currentUser.id,
            receiverId: facultyId,
            eventId: newEvent.id,
            approvalRelatedId: newEvent.id,
            status: .pending,
            remarks: [Remark(id: UUID(), text: "Event creation approval requested", authorId: currentUser.id, createdAt: Date())],
            createdAt: Date(),
            updatedAt: nil
        )
        appSession.approvalStore.addApproval(eventApproval)
        
        if !budgetItems.isEmpty {
            let budgetApproval = Approval(
                id: UUID(),
                type: .budget,
                senderId: currentUser.id,
                receiverId: facultyId,
                eventId: newEvent.id,
                approvalRelatedId: UUID(), // Reference for the collection
                status: .pending,
                remarks: [Remark(id: UUID(), text: "Budget approval requested for \(budgetItems.count) items", authorId: currentUser.id, createdAt: Date())],
                createdAt: Date(),
                updatedAt: nil
            )
            appSession.approvalStore.addApproval(budgetApproval)
        }
        
        if !universityResources.isEmpty || !rentalResources.isEmpty {
            let resourceApproval = Approval(
                id: UUID(),
                type: .resource,
                senderId: currentUser.id,
                receiverId: facultyId,
                eventId: newEvent.id,
                approvalRelatedId: UUID(), // Reference for the collection
                status: .pending,
                remarks: [Remark(id: UUID(), text: "Resource approval requested for \(universityResources.count + rentalResources.count) items", authorId: currentUser.id, createdAt: Date())],
                createdAt: Date(),
                updatedAt: nil
            )
            appSession.approvalStore.addApproval(resourceApproval)
        }
        
        // Venue Approval
        let venueApproval = Approval(
            id: UUID(),
            type: .venue,
            senderId: currentUser.id,
            receiverId: facultyId,
            eventId: newEvent.id,
            approvalRelatedId: UUID(),
            status: .pending,
            remarks: [Remark(id: UUID(), text: "Venue booking approval requested for \(venue)", authorId: currentUser.id, createdAt: Date())],
            createdAt: Date(),
            updatedAt: nil
        )
        appSession.approvalStore.addApproval(venueApproval)
        
        onSave(newEvent)
        dismiss()
    }

    
}

struct BudgetSummarySheet: View {
    let items: [DraftBudgetItem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Quantity: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                let price = Double(item.price) ?? 0
                                Text("₹\(Int(price * Double(item.quantity)))")
                                    .font(.headline)
                                Text("₹\(Int(price)) per unit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Budget Items")
                }
                
                Section {
                    let total = items.reduce(0) { $0 + (Double($1.price) ?? 0) * Double($1.quantity) }
                    HStack {
                        Text("Total Budget")
                            .font(.headline)
                        Spacer()
                        Text("₹\(Int(total))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Budget Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ResourceSummarySheet: View {
    let universityItems: [DraftResourceItem]
    let rentalItems: [DraftResourceItem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if !universityItems.isEmpty {
                    Section {
                        ForEach(universityItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("Quantity: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("University")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("University Resources")
                    }
                }
                
                if !rentalItems.isEmpty {
                    Section {
                        ForEach(rentalItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("Quantity: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    let price = Double(item.price) ?? 0
                                    Text("₹\(Int(price * Double(item.quantity)))")
                                        .font(.headline)
                                    Text("₹\(Int(price)) per unit")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("External Rentals")
                    }
                }
                
                if !rentalItems.isEmpty {
                    Section {
                        let total = rentalItems.reduce(0) { $0 + (Double($1.price) ?? 0) * Double($1.quantity) }
                        HStack {
                            Text("Total Rental Cost")
                                .font(.headline)
                            Spacer()
                            Text("₹\(Int(total))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Resource Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CreateNewEventView { _ in }
        .environment(MockData.session(for: .clubLead))
}
