//
//  AppSession.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import Foundation
import Observation

@Observable
final class AppSession {
    var currentUser: User?
    var currentRole: AppRole?
    var isLoggedIn: Bool = false
    var isRefreshing: Bool = false
    
    var activeDashboardTab: Int = 0
    var activeExploreTab: Int = 0
    
    var clubAchievementStore: AchievementStore
    var announcementStore: AnnouncementStore
    var clubLinkStore: ClubLinkStore
    var clubFileStore: ClubFileStore
    var clubImageStore: ClubImageStore
    var clubStore: ClubStore
    var eventStore: EventStore
    var taskStore: TaskStore
    var venueStore: VenueStore
    var studentDashboardStore: StudentDashboardStore
    var chatStore: ChatStore
    var approvalStore: ApprovalStore
    var activityStore: ActivityStore
    var registrationStore: RegistrationStore
    
    var registeredEventIds: Set<UUID> = []
    var favouritedEventIds: Set<UUID> = []
    
    var selectedTask: Tasks? = nil
    var selectedActivity: Activity? = nil
    
    var currentUserClubId: UUID? {
        if let clubId = currentUser?.clubId {
            return clubId
        }
        if currentUser?.role == .vicePresident {
            return clubStore.allClubs.first(where: { $0.vicePresidentId == currentUser?.id })?.id
        }
        return nil
    }

    var currentTime: Date = Date()
    private var timer: Timer?

    init() {
        let clubStore = ClubStore()
        let eventStore = EventStore()
        let approvalStore = ApprovalStore()
        let taskStore = TaskStore()
        
        self.clubStore = clubStore
        self.eventStore = eventStore
        self.approvalStore = approvalStore
        self.taskStore = taskStore
        self.venueStore = VenueStore()
        
        self.clubAchievementStore = AchievementStore(clubId: clubStore.club.id)
        self.announcementStore = AnnouncementStore()
        self.clubLinkStore = ClubLinkStore()
        self.clubFileStore = ClubFileStore()
        self.clubImageStore = ClubImageStore(clubId: clubStore.club.id)
        self.studentDashboardStore = StudentDashboardStore(clubStore: clubStore, eventStore: eventStore)
        self.chatStore = ChatStore()
        self.activityStore = ActivityStore()
        self.registrationStore = RegistrationStore()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    @MainActor
    func signIn(user: User, role: AppRole) async {
        currentUser = user
        currentRole = role
        isLoggedIn = true
        
        await refreshData()
    }

    @MainActor
    func refreshData() async {
        guard isLoggedIn, let user = currentUser else { return }
        isRefreshing = true
        
        print("DEBUG: Starting Data Refresh for \(user.name)...")
        
        // 1. Fetch User's specific Club Details FIRST
        if let clubId = user.clubId {
            do {
                print("DEBUG: Loading personal club data for \(clubId)")
                try await clubStore.fetchClubDetails(id: clubId)
                
                // Update achievement store with the real ID
                self.clubAchievementStore = AchievementStore(clubId: clubId)
                
                try await activityStore.fetchActivities(clubId: clubId)
                try await clubFileStore.fetchFiles(clubId: clubId)
                try await clubLinkStore.fetchLinks(clubId: clubId)
                print("DEBUG: Personal club data loaded: \(clubStore.club.name)")
            } catch {
                print("DEBUG ERROR: Personal club data failed: \(error.localizedDescription)")
            }
        }

        // 2. Load Global Data in parallel (Non-blocking)
        async let clubsTask: Void = { try? await clubStore.fetchAllClubs() }()
        async let usersTask: Void = { try? await clubStore.fetchAllUsers() }()
        async let eventsTask: Void = { try? await eventStore.fetchAllEvents() }()
        async let approvalsTask: Void = { try? await approvalStore.fetchApprovals() }()
        async let budgetsTask: Void = { try? await approvalStore.fetchBudgets() }()
        async let resourcesTask: Void = { try? await approvalStore.fetchResources() }()
        async let registrationsTask: Void = { try? await registrationStore.fetchRegistrations() }()
        async let tasksTask: Void = { try? await taskStore.fetchTasks() }()
        async let announcementsTask: Void = { try? await announcementStore.fetchAnnouncements() }()
        async let venuesTask: Void = { try? await venueStore.fetchVenues() }()
        
        await clubsTask
        await usersTask
        await eventsTask
        await approvalsTask
        await budgetsTask
        await resourcesTask
        await registrationsTask
        await tasksTask
        await announcementsTask
        await venuesTask
        
        // 3. Sync registrations
        let userRegistrations = registrationStore.registrations.filter { $0.userId == user.id }
        self.registeredEventIds = Set(userRegistrations.compactMap { $0.eventId })
        self.studentDashboardStore.registeredEventIds = self.registeredEventIds
        
        print("DEBUG: Data Sync Sequence Complete")
        isRefreshing = false
    }

    func signOut() {
        currentUser = nil
        currentRole = nil
        isLoggedIn = false
        registeredEventIds = []
        favouritedEventIds = []
        studentDashboardStore.registeredEventIds = []
    }
    
    func updateUserProfile(name: String, bio: String, phoneNumber: String, course: String, year: String, imageData: Data?) {
        guard var user = currentUser else { return }
        user.name = name
        user.bio = bio
        user.phoneNumber = phoneNumber
        user.course = course
        user.year = year
        user.imageData = imageData
        currentUser = user
        
        // Sync with global users list
        clubStore.updateMember(updatedUser: user)
    }
    
    @MainActor
    func registerForEvent(id: UUID) async {
        guard let userId = currentUser?.id else { return }
        
        // Find the event to check max participants
        guard let event = eventStore.events.first(where: { $0.id == id }) else { return }
        let currentCount = registrationStore.getRegistrations(for: id).count
        
        // First Come First Serve: Check if full before allowing new registration
        if !registeredEventIds.contains(id) && currentCount >= event.maxParticipants {
            print("Registration failed: Event is full")
            return
        }
        
        do {
            try await registrationStore.toggleRegistration(eventId: id, userId: userId)
            
            // Update registration count locally for immediate UI feedback
            if let index = eventStore.events.firstIndex(where: { $0.id == id }) {
                let isRegistering = !registeredEventIds.contains(id)
                let currentRegistrations = eventStore.events[index].numberOfRegistrations ?? 0
                
                if isRegistering {
                    eventStore.events[index].numberOfRegistrations = currentRegistrations + 1
                    registeredEventIds.insert(id)
                } else {
                    eventStore.events[index].numberOfRegistrations = max(0, currentRegistrations - 1)
                    registeredEventIds.remove(id)
                }
            }
            
            studentDashboardStore.registeredEventIds = registeredEventIds
        } catch {
            print("Registration toggle failed: \(error)")
        }
    }
    
    func toggleFavorite(id: UUID) {
        if favouritedEventIds.contains(id) {
            favouritedEventIds.remove(id)
        } else {
            favouritedEventIds.insert(id)
        }
    }
    
    @MainActor
    func checkAndAutoApproveEvent(eventId: UUID) async {
        let allResources = approvalStore.resources.filter { $0.eventId == eventId }
        let allVenues = approvalStore.approvals.filter { $0.eventId == eventId && $0.type == .venue }
        let allBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
        
        let isFullyApproved = allResources.allSatisfy { $0.status == .approved } &&
                             allVenues.allSatisfy { $0.status == .approved } &&
                             allBudgets.allSatisfy { $0.status == .approved }
        
        if isFullyApproved {
            if let eventApproval = approvalStore.approvals.first(where: { $0.eventId == eventId && $0.type == .event && $0.status == .pending }) {
                try? await approvalStore.updateApproval(id: eventApproval.id, status: .approved)
            }
            try? await eventStore.updateEventStatus(id: eventId, status: .approved)
        }
    }
    
    @MainActor
    func forwardVPApproval(eventId: UUID, club: Club, senderId: UUID) async throws {
        let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
        let facultyId = club.facultyId ?? eventManagementTeamID
        let presidentUserId = clubStore.allUsers.first(where: { $0.role == .president })?.id ?? MockData.presidentId
        
        let eventBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
        let eventResources = approvalStore.resources.filter { $0.eventId == eventId }
        
        var approvalsToSave: [Approval] = []
        var remarksToSave: [RemarkMessage] = []
        
        // 1. Budget Approvals
        for budget in eventBudgets {
            let budgetApproval = Approval(
                id: UUID(),
                type: .budget,
                senderId: senderId,
                receiverId: presidentUserId,
                eventId: eventId,
                approvalRelatedId: budget.id,
                status: .pending,
                remarks: [],
                createdAt: Date(),
                updatedAt: nil
            )
            approvalsToSave.append(budgetApproval)
            remarksToSave.append(RemarkMessage(
                id: UUID(),
                approvalId: budgetApproval.id,
                authorId: senderId,
                content: "Forwarded: Budget approval requested for \(budget.itemName)",
                createdAt: Date()
            ))
        }
        
        // 2. Resource Approvals
        for resource in eventResources {
            let resApproval = Approval(
                id: UUID(),
                type: .resource,
                senderId: senderId,
                receiverId: facultyId,
                eventId: eventId,
                approvalRelatedId: resource.id,
                status: .pending,
                remarks: [],
                createdAt: Date(),
                updatedAt: nil
            )
            approvalsToSave.append(resApproval)
            remarksToSave.append(RemarkMessage(
                id: UUID(),
                approvalId: resApproval.id,
                authorId: senderId,
                content: "Forwarded: Resource approval requested for \(resource.name)",
                createdAt: Date()
            ))
        }
        
        // 3. Faculty Event Approval
        let facultyEventApproval = Approval(
            id: UUID(),
            type: .event,
            senderId: senderId,
            receiverId: facultyId,
            eventId: eventId,
            approvalRelatedId: eventId,
            status: .pending,
            remarks: [],
            createdAt: Date(),
            updatedAt: nil
        )
        approvalsToSave.append(facultyEventApproval)
        remarksToSave.append(RemarkMessage(
            id: UUID(),
            approvalId: facultyEventApproval.id,
            authorId: senderId,
            content: "Forwarded: Event creation approval requested",
            createdAt: Date()
        ))
        
        // 4. Venue Booking Approval
        if let event = eventStore.events.first(where: { $0.id == eventId }) {
            let selectedVenue = venueStore.allVenues.first(where: { $0.name == event.location })
            let venueApproval = Approval(
                id: UUID(),
                type: .venue,
                senderId: senderId,
                receiverId: facultyId,
                eventId: eventId,
                approvalRelatedId: selectedVenue?.id ?? eventId,
                status: .pending,
                remarks: [],
                createdAt: Date(),
                updatedAt: nil
            )
            approvalsToSave.append(venueApproval)
            remarksToSave.append(RemarkMessage(
                id: UUID(),
                approvalId: venueApproval.id,
                authorId: senderId,
                content: "Forwarded: Venue booking approval requested for \(event.location)",
                createdAt: Date()
            ))
        }
        
        if !approvalsToSave.isEmpty {
            try await approvalStore.submitApprovalRequests(approvalsToSave)
        }
        if !remarksToSave.isEmpty {
            try await approvalStore.addRemarks(remarksToSave)
        }
    }
}
