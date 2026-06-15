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
    @State private var isSaving = false
    @State private var showSuccessView = false
    @State private var currentEventId = UUID()
    @State private var selectedClubIds: Set<UUID> = []
    @State private var isShowingPublishConfirmation = false
    @State private var isRegistrationOpen = true


    
    // Venues are now fetched from VenueStore
    
    var body: some View {
        if showSuccessView {
            let isPresident = appSession.currentUser?.role == .president
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: isPresident ? "checkmark.circle.fill" : "doc.text.badge.plus")
                    .font(.system(size: 80))
                    .foregroundStyle(isPresident ? Color.green.gradient : Color.orange.gradient)
                    .symbolEffect(.bounce, options: .nonRepeating)
                    .padding(.bottom, 8)
                
                VStack(spacing: 16) {
                    Text(isPresident ? "Event Published" : "Draft Sent")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(isPresident ? "Your event '\(eventName)' has been successfully published and is now live." : "Your event '\(eventName)' has been saved as a draft and sent to the Vice President for review.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if !isPresident {
                        NavigationLink(destination: LeadEventApprovalDetailView(eventId: currentEventId)) {
                            Text("View Event Draft")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .tint(.orange)
                    }
                    
                    if isPresident {
                        Button {
                            dismiss()
                        } label: {
                            Text("Go to Dashboard")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .tint(.orange)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Text("Go to Dashboard")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .tint(.orange)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
        } else {
            Form {
                if appSession.currentUser?.role == .president {
                    Section {
                        NavigationLink {
                            MultiClubSelectionView(selectedClubIds: $selectedClubIds)
                        } label: {
                            HStack {
                                Text("Associated Clubs")
                                Spacer()
                                if selectedClubIds.isEmpty {
                                    Text("None (All Clubs)")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(selectedClubIds.count) Clubs")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Club Association")
                    }
                    
                    Section {
                        Toggle("Open Registration", isOn: $isRegistrationOpen)
                            .tint(.orange)
                    } header: {
                        Text("Registration Status")
                    }
                }
                
                Section {
                    TextField("Event Name", text: $eventName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Event Category", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

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
                    let conflictingEvents = appSession.eventStore.events.filter { e in
                        e.id != currentEventId &&
                        (e.status == .pending || e.status == .approved || e.status == .published) &&
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
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Venue")
                }
                
                if appSession.currentUser?.role != .president {
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
                }

                Section {
                    TextField("Expected Participants (Optional)", text: $participants)
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
                        e.id != currentEventId &&
                        e.location == venue &&
                        (e.status == .pending || e.status == .approved || e.status == .published) &&
                        (startDate < e.endDate) && (e.startDate < endDate)
                    }
                    
                    let isInvalidTime = startDate >= endDate
                    
                    Button {
                        if appSession.currentUser?.role == .president {
                            isShowingPublishConfirmation = true
                        } else {
                            isSaving = true
                            saveEvent()
                        }
                    } label: {
                        Text(appSession.currentUser?.role == .president ? "Publish Event" : "Send Approval")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isVenueBooked || isSaving || isInvalidTime)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    
                    if isVenueBooked {
                        Text("Selected venue is unavailable for this time slot")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    } else if startDate == endDate {
                        Text("Start and End time cannot be the same")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    } else if endDate < startDate {
                        Text("End date must be after start date")
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
            .alert("Publish Event", isPresented: $isShowingPublishConfirmation) {
                Button("Publish", role: .none) {
                    isSaving = true
                    saveEvent()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to publish this event directly? It will be visible to all users immediately.")
            }
            .onAppear {
                // Generate a fresh UUID every time this view appears so that
                // repeated event creations never collide on the primary key.
                if !showSuccessView {
                    currentEventId = UUID()
                    errorMessage = nil
                    isSaving = false
                }
            }
        }
    }
    
    private func saveEvent() {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter an event name."
            isSaving = false
            return
        }
        
        guard !trimmedDescription.isEmpty else {
            errorMessage = "Please enter an event description."
            isSaving = false
            return
        }
        
        guard endDate >= startDate else {
            errorMessage = "End date must be after start date."
            isSaving = false
            return
        }
        
        guard let currentUser = appSession.currentUser else {
            errorMessage = "No logged in user found."
            isSaving = false
            return
        }
        
        let resolvedClubId: UUID?
        var resolvedClubIds: [UUID] = []
        if currentUser.role == .president {
            resolvedClubId = nil
            resolvedClubIds = Array(selectedClubIds)
        } else {
            guard let userClubId = currentUser.clubId else {
                errorMessage = "Error: Your user account is not linked to any club."
                isSaving = false
                return
            }
            resolvedClubId = userClubId
            resolvedClubIds = [userClubId]
        }
        
        let isPresident = currentUser.role == .president
        let maxParticipantsVal: Int
        if participants.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            maxParticipantsVal = 999999
        } else {
            guard let parsed = Int(participants.trimmingCharacters(in: .whitespacesAndNewlines)), parsed > 0 else {
                errorMessage = "Expected participants must be a number greater than 0."
                isSaving = false
                return
            }
            maxParticipantsVal = parsed
        }
        
        let newEvent = Event(
            id: currentEventId,
            name: trimmedName,
            title: trimmedName,
            description: trimmedDescription,
            startDate: startDate,
            endDate: endDate,
            startTime: startDate,
            endTime: endDate,
            numberOfVolunteers: 0,
            numberOfRegistrations: 0,
            maxParticipants: maxParticipantsVal,
            registrationType: registrationType,
            location: venue,
            clubId: resolvedClubId,
            clubIds: resolvedClubIds,
            createdBy: currentUser.id,
            category: selectedCategory,
            status: isPresident ? .published : .pending,
            isRegistrationOpen: isRegistrationOpen,
            registrationDeadline: Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate,
            bannerImage: nil,
            imageData: imageData,
            agenda: agenda,
            registrationForm: customFormFields,
            createdAt: Date()
        )

        print("DEBUG: Attempting to create event:")
        print("  - ID: \(newEvent.id)")
        print("  - Name: \(newEvent.name)")
        print("  - ClubID: \(newEvent.clubId)")
        print("  - CreatedBy: \(newEvent.createdBy)")
        print("  - Status: \(newEvent.status.rawValue)")
        
        if currentUser.role != .president && currentUser.clubId == nil {
            print("WARNING: currentUser.clubId is NIL! RLS will likely fail.")
            errorMessage = "Error: Your user account is not linked to any club. Please contact your administrator."
            isSaving = false
            return
        }

        Task {
            do {
                // 0. Upload banner image to Supabase Storage (if selected)
                var eventToSave = newEvent
                if let imgData = imageData {
                    do {
                        let bannerURL = try await ImageUploadService.shared.uploadEventBanner(
                            imageData: imgData,
                            eventId: currentEventId
                        )
                        eventToSave.bannerImage = bannerURL
                        print("DEBUG: Banner image uploaded successfully: \(bannerURL)")
                    } catch {
                        print("WARNING: Banner image upload failed: \(error.localizedDescription). Proceeding without banner.")
                        // Continue without banner rather than failing the entire event creation
                    }
                }
                
                // 1. Save the main event (pass isCouncil if isPresident)
                try await appSession.eventStore.createEvent(eventToSave, isCouncil: isPresident)
                
                if !isPresident {
                    let club = appSession.clubStore.allClubs.first(where: { $0.id == newEvent.clubId })
                    let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
                    let facultyId = club?.facultyId ?? eventManagementTeamID
                    let presidentUserId = appSession.clubStore.allUsers.first(where: { $0.role == .president })?.id ?? MockData.presidentId
                    
                    var budgetsToSave: [Budget] = []
                    var resourcesToSave: [Resource] = []
                    var approvalsToSave: [Approval] = []
                    
                    // 2. Prepare Budget Items
                    for item in budgetItems {
                        let budgetId = UUID()
                        let price = Double(item.price) ?? 0
                        let budget = Budget(
                            id: budgetId,
                            eventId: newEvent.id,
                            itemName: item.name,
                            unitPrice: price,
                            quantity: item.quantity,
                            status: .pending,
                            addedBy: currentUser.id,
                            remarks: [],
                            createdAt: Date()
                        )
                        budgetsToSave.append(budget)
                    }
                    
                    // 3. Prepare Resource Items
                    for item in universityResources {
                        let resourceId = UUID()
                        let resource = Resource(
                            id: resourceId, 
                            eventId: newEvent.id,
                            name: item.name,
                            quantity: item.quantity,
                            type: .university,
                            status: .pending,
                            addedBy: currentUser.id,
                            remarks: [],
                            createdAt: Date()
                        )
                        resourcesToSave.append(resource)
                    }
                    
                    for item in rentalResources {
                        let resourceId = UUID()
                        let price = Double(item.price) ?? 0
                        let resource = Resource(
                            id: resourceId, 
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
                        resourcesToSave.append(resource)
                    }

                    // 5. Batch Save Budgets & Resources first so that routing functions can query them
                    if !budgetsToSave.isEmpty {
                        try await appSession.approvalStore.addBudgets(budgetsToSave)
                    }
                    if !resourcesToSave.isEmpty {
                        try await appSession.approvalStore.addResources(resourcesToSave)
                    }

                    // Check if Vice President exists for the club
                    if let vicePresidentUserId = club?.vicePresidentId {
                        // Send to Vice President first as a draft
                        let eventApproval = Approval(
                            id: UUID(),
                            type: .event,
                            senderId: currentUser.id,
                            receiverId: vicePresidentUserId,
                            eventId: newEvent.id,
                            approvalRelatedId: newEvent.id,
                            status: .pending,
                            remarks: [],
                            createdAt: Date(),
                            updatedAt: nil
                        )
                        approvalsToSave.append(eventApproval)
                    } else if let club = club {
                        // Let AppSession handle the sequential forwarding:
                        // First to President if budget exists, else straight to EMT.
                        try await appSession.forwardToPresidentBudgetApproval(
                            eventId: newEvent.id,
                            club: club,
                            senderId: currentUser.id
                        )
                    }
                    
                    if !approvalsToSave.isEmpty {
                        try await appSession.approvalStore.submitApprovalRequests(approvalsToSave)
                    }
                }
                
                await MainActor.run {
                    onSave(newEvent)
                    withAnimation {
                        showSuccessView = true
                    }
                }
            } catch {
                isSaving = false
                errorMessage = "Failed to save event: \(error.localizedDescription)"
                print("DEBUG ERROR: Event creation failed - \(error.localizedDescription)")
            }
        }
    }

    private func resetForm() {
        currentEventId = UUID()
        eventName = ""
        eventDescription = ""
        // ... other properties if needed ...
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

struct MultiClubSelectionView: View {
    @Environment(AppSession.self) var appSession
    @Binding var selectedClubIds: Set<UUID>
    
    var body: some View {
        List {
            ForEach(appSession.clubStore.allClubs) { club in
                Button {
                    if selectedClubIds.contains(club.id) {
                        selectedClubIds.remove(club.id)
                    } else {
                        selectedClubIds.insert(club.id)
                    }
                } label: {
                    HStack {
                        Text(club.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedClubIds.contains(club.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Clubs")
    }
}
