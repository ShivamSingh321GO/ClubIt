//
//  AppSession.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import Foundation
import Observation
import Supabase

@Observable
final class AppSession {
    var currentUser: User?
    var currentRole: AppRole?
    var isLoggedIn: Bool = false
    var isRefreshing: Bool = false
    private var lastRefreshDate: Date = .distantPast
    
    var unreadMessageCount: Int = 0
    var showWithdrawSuccessAlert: Bool = false
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
    var attendanceStore: AttendanceStore
    
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
        
        self.clubAchievementStore = AchievementStore()
        self.announcementStore = AnnouncementStore()
        self.clubLinkStore = ClubLinkStore()
        self.clubFileStore = ClubFileStore()
        self.clubImageStore = ClubImageStore(clubId: clubStore.club.id)
        self.studentDashboardStore = StudentDashboardStore(clubStore: clubStore, eventStore: eventStore)
        self.chatStore = ChatStore()
        self.activityStore = ActivityStore()
        self.registrationStore = RegistrationStore()
        self.attendanceStore = AttendanceStore()
        
        self.chatStore.eventStore = eventStore
        
        startBackgroundPolling()
    }
    
    /// Starts a 30-second polling timer that silently syncs key data from Supabase.
    /// This ensures events, approvals, and tasks created by other users appear
    /// without requiring a manual pull-to-refresh or re-login.
    private func startBackgroundPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
            guard let self = self, self.isLoggedIn else { return }
            Task { @MainActor in
                await self.silentRefreshKeyData()
            }
        }
    }
    
    /// Lightweight silent refresh that fetches only the frequently-changing tables
    /// (events, approvals, budgets, resources, tasks, chats) without showing any loading UI.
    @MainActor
    func silentRefreshKeyData() async {
        guard isLoggedIn, let user = currentUser else { return }
        
        // Fetch key data in parallel including clubs
        async let eventsTask: Void = { try? await self.eventStore.fetchAllEvents() }()
        async let approvalsTask: Void = { try? await self.approvalStore.fetchApprovals() }()
        async let budgetsTask: Void = { try? await self.approvalStore.fetchBudgets() }()
        async let resourcesTask: Void = { try? await self.approvalStore.fetchResources() }()
        async let tasksTask: Void = { try? await self.taskStore.fetchTasks() }()
        async let clubsTask: Void = { try? await self.clubStore.fetchAllClubs() }()
        async let usersTask: Void = { try? await self.clubStore.fetchAllUsers() }()
        
        // If user is affiliated with a club, refresh details in parallel
        async let clubDetailsTask: Void = {
            if let clubId = user.clubId {
                try? await self.clubStore.fetchClubDetails(id: clubId)
            }
        }()
        
        await eventsTask
        await approvalsTask
        await budgetsTask
        await resourcesTask
        await tasksTask
        await clubsTask
        await usersTask
        await clubDetailsTask
        
        await chatStore.autoArchiveExpiredEventChats(events: eventStore.events)
        
        print("DEBUG: Silent background sync complete")
    }

    @MainActor
    func restoreSession() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let authService = SupabaseAuthService()
            let user = try await authService.fetchUserProfile(userId: session.user.id)
            await self.signIn(user: user, role: user.role)
        } catch {
            print("No active session or session restore failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func signIn(user: User, role: AppRole) async {
        currentUser = user
        currentRole = role
        isLoggedIn = true
        lastRefreshDate = .distantPast // Reset debounce so initial load always fires
        
        // Initialize chat store with the logged-in user's ID and start realtime
        chatStore.userId = user.id
        chatStore.startRealtimeSubscription()
        announcementStore.startRealtimeSubscription()
        
        await refreshData()
    }

    @MainActor
    func refreshData() async {
        guard isLoggedIn, let user = currentUser else { return }
        // Debounce: skip if already refreshing or if last refresh was less than 5 seconds ago
        guard !isRefreshing, Date().timeIntervalSince(lastRefreshDate) > 5 else {
            print("DEBUG: Skipping refresh (debounced)")
            return
        }
        isRefreshing = true
        lastRefreshDate = Date()
        
        print("DEBUG: Starting Data Refresh for \(user.name)...")
        
        // 1. Fetch User's specific Club Details FIRST
        if let clubId = user.clubId {
            do {
                print("DEBUG: Loading personal club data for \(clubId)")
                try await clubStore.fetchClubDetails(id: clubId)
                
                // Fetch achievements from Supabase
                try await clubAchievementStore.fetchAchievements(clubId: clubId)
                
                try await activityStore.fetchActivities(clubId: clubId)
                try await clubFileStore.fetchFiles(clubId: clubId)
                try await clubLinkStore.fetchLinks(clubId: clubId)
                try await clubImageStore.fetchImages(clubId: clubId)
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
        async let chatsTask: Void = { await chatStore.fetchChatsIfNeeded() }()
        
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
        await chatsTask
        
        await chatStore.autoArchiveExpiredEventChats(events: eventStore.events)
        
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
        chatStore.stopRealtimeSubscription()
        chatStore.clearData()
        announcementStore.stopRealtimeSubscription()
    }
    
    @MainActor
    func updateUserProfile(name: String, bio: String, phoneNumber: String, course: String, year: String, imageData: Data?) async throws {
        guard var user = currentUser else { return }
        var profileImgUrl = user.profileImg ?? ""
        
        let client = SupabaseManager.shared.client
        
        // 1. Upload profile image to Supabase Storage bucket 'userProfile-images' if new imageData is provided
        if let imageData {
            do {
                // Remove older avatar files in this user's folder to avoid storage bloat
                if let files = try? await client.storage.from("userProfile-images").list(path: user.id.uuidString) {
                    let pathsToDelete = files.map { "\(user.id.uuidString)/\($0.name)" }
                    if !pathsToDelete.isEmpty {
                        _ = try? await client.storage.from("userProfile-images").remove(paths: pathsToDelete)
                    }
                }
                
                // Use a unique filename incorporating a timestamp to bypass cached URL/image lookups
                let storagePath = "\(user.id.uuidString)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
                try await client.storage
                    .from("userProfile-images")
                    .upload(
                        storagePath,
                        data: imageData,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )
                
                let publicURL = try client.storage
                    .from("userProfile-images")
                    .getPublicURL(path: storagePath)
                
                profileImgUrl = publicURL.absoluteString
                print("DEBUG: Uploaded user profile image. Public URL: \(profileImgUrl)")
            } catch {
                print("DEBUG ERROR: Failed to upload user profile image: \(error.localizedDescription)")
                throw error
            }
        }
        
        // 2. Update Supabase table
        let updateData: [String: AnyJSON] = [
            "name": .string(name),
            "bio": .string(bio),
            "phone_number": .string(phoneNumber),
            "course": .string(course),
            "year": .string(year),
            "profile_img": .string(profileImgUrl)
        ]
        
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: user.id)
            .execute()
        
        // 3. Update local state
        user.name = name
        user.bio = bio
        user.phoneNumber = phoneNumber
        user.course = course
        user.year = year
        user.profileImg = profileImgUrl
        user.imageData = nil // Clear local imageData so the view uses the remote URL
        currentUser = user
        
        // Sync with global users list
        clubStore.updateMember(updatedUser: user)
        
        // Refresh global users list from database so other views see the changes
        try? await clubStore.fetchAllUsers()
    }
    
    @MainActor
    func registerForEvent(id: UUID, answers: [String: String]? = nil) async -> Bool {
        guard let userId = currentUser?.id else { return false }
        
        // Find the event to check max participants
        guard let event = eventStore.events.first(where: { $0.id == id }) else { return false }
        let currentCount = registrationStore.getRegistrations(for: id).count
        
        // First Come First Serve: Check if full before allowing new registration (Bypass for president)
        if currentUser?.role != .president {
            if !registeredEventIds.contains(id) && event.maxParticipants > 0 && event.maxParticipants < 999999 && currentCount >= event.maxParticipants {
                print("Registration failed: Event is full")
                return false
            }
        }
        
        let isRegistering = !registeredEventIds.contains(id)
        
        do {
            try await registrationStore.toggleRegistration(eventId: id, userId: userId, answers: answers)
            
            // Update registration count locally for immediate UI feedback
            if let index = eventStore.events.firstIndex(where: { $0.id == id }) {
                let currentRegistrations = eventStore.events[index].numberOfRegistrations ?? 0
                
                if isRegistering {
                    eventStore.events[index].numberOfRegistrations = currentRegistrations + 1
                    registeredEventIds.insert(id)
                    
                    // Add user to the event's General chat globally
                    print("DEBUG: [AppSession] Registering user \(userId) for event '\(event.title)' clubId=\(event.clubId?.uuidString ?? "nil")")
                    if let clubId = event.clubId {
                        await chatStore.addUserToEventChatsGlobally(userId: userId, eventId: id, eventTitle: event.title, clubId: clubId)
                    } else {
                        print("DEBUG: [AppSession] WARNING: event.clubId is nil, cannot add to chat")
                    }
                } else {
                    eventStore.events[index].numberOfRegistrations = max(0, currentRegistrations - 1)
                    registeredEventIds.remove(id)
                    
                    // Remove user from the event's General chat globally
                    print("DEBUG: [AppSession] Withdrawing user \(userId) from event '\(event.title)' clubId=\(event.clubId?.uuidString ?? "nil")")
                    if let clubId = event.clubId {
                        await chatStore.removeUserFromEventChatsGlobally(userId: userId, eventId: id, eventTitle: event.title, clubId: clubId)
                    }
                }
            }
            
            studentDashboardStore.registeredEventIds = registeredEventIds
            return true
        } catch {
            print("Registration toggle failed: \(error)")
            return false
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
    func forwardToPresidentBudgetApproval(eventId: UUID, club: Club, senderId: UUID) async throws {
        let presidentUserId = clubStore.allUsers.first(where: { $0.role == .president })?.id ?? MockData.presidentId
        let eventBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
        
        if eventBudgets.isEmpty {
            // No budgets to approve, skip to EMT directly!
            try await forwardToEMTApproval(eventId: eventId, club: club, senderId: senderId)
            return
        }
        
        var approvalsToSave: [Approval] = []
        
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
        }
        
        if !approvalsToSave.isEmpty {
            try await approvalStore.submitApprovalRequests(approvalsToSave)
        }
    }
    
    @MainActor
    func forwardToEMTApproval(eventId: UUID, club: Club, senderId: UUID) async throws {
        let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
        let facultyId = club.facultyId ?? eventManagementTeamID
        let eventResources = approvalStore.resources.filter { $0.eventId == eventId }
        
        var approvalsToSave: [Approval] = []
        
        // 1. Resource Approvals
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
        }
        
        // 2. Faculty Event Approval
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
        
        // 3. Venue Booking Approval
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
        }
        
        if !approvalsToSave.isEmpty {
            try await approvalStore.submitApprovalRequests(approvalsToSave)
        }
    }
    
    @MainActor
    func approveBudgetAndCheckForwarding(budget: Budget, status: ApprovalStatus) async throws {
        // 1. Update in database via store
        try await approvalStore.updateBudgetStatus(id: budget.id, status: status)
        
        // 2. If approved, check if all budgets for this event are approved
        if status == .approved {
            guard let eventId = budget.eventId else { return }
            
            // Filter budgets locally to see if all are approved
            let eventBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
            let allApproved = eventBudgets.allSatisfy { $0.status == .approved }
            
            if allApproved {
                // If all budgets are approved, forward venue/resource approvals to EMT
                if let event = eventStore.events.first(where: { $0.id == eventId }),
                   let club = clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                    try await forwardToEMTApproval(
                        eventId: eventId,
                        club: club,
                        senderId: currentUser?.id ?? UUID()
                    )
                }
            }
        }
    }
}
