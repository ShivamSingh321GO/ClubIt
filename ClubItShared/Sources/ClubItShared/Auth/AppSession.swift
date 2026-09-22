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
public final class AppSession {
    public var currentUser: User?
    public var currentRole: AppRole?
    public var isLoggedIn: Bool = false
    public var isRefreshing: Bool = false
    private var lastRefreshDate: Date = .distantPast
    
    public var unreadMessageCount: Int = 0
    public var showWithdrawSuccessAlert: Bool = false
    public var activeDashboardTab: Int = 0
    public var activeExploreTab: Int = 0
    
    public var organizationProfile: OrganizationProfile?
    public var organizationFeatures: OrganizationFeatures? {
        organizationProfile?.features
    }
    
    public var subgroupAchievementStore: AchievementStore
    public var announcementStore: AnnouncementStore
    public var subgroupLinkStore: SubgroupLinkStore
    public var subgroupFileStore: SubgroupFileStore
    public var subgroupImageStore: SubgroupImageStore
    public var subgroupStore: SubgroupStore
    public var eventStore: EventStore
    public var taskStore: TaskStore
    public var venueStore: VenueStore
    public var studentDashboardStore: StudentDashboardStore
    public var chatStore: ChatStore
    public var approvalStore: ApprovalStore
    public var activityStore: ActivityStore
    public var registrationStore: RegistrationStore
    public var attendanceStore: AttendanceStore
    public var routingService: ApprovalFlowRoutingService
    
    
    public var registeredEventIds: Set<UUID> = []
    public var favouritedEventIds: Set<UUID> = []
    
    public var selectedTask: Tasks? = nil
    public var selectedActivity: Activity? = nil
    
    public var currentUserSubgroupId: UUID? {
        if let subgroupId = currentUser?.subgroupId {
            return subgroupId
        }
        if currentUser?.role == .groupSubLead {
            return subgroupStore.allSubgroups.first(where: { $0.vicePresidentId == currentUser?.id })?.id
        }
        return nil
    }

    public var isExploreVisible: Bool {
        organizationFeatures?.isExploreVisible ?? true
    }
    
    public var exploreTabTitle: String {
        organizationFeatures?.exploreTabTitle ?? "Explore"
    }
    
    public var exploreTabIcon: String {
        organizationFeatures?.exploreTabIcon ?? "globe"
    }

    public var currentTime: Date = Date()
    private var timer: Timer?

    public init() {
        let subgroupStore = SubgroupStore()
        let eventStore = EventStore()
        let approvalStore = ApprovalStore()
        let taskStore = TaskStore()
        
        self.subgroupStore = subgroupStore
        self.eventStore = eventStore
        self.approvalStore = approvalStore
        self.taskStore = taskStore
        self.venueStore = VenueStore()
        
        self.subgroupAchievementStore = AchievementStore()
        self.announcementStore = AnnouncementStore()
        self.subgroupLinkStore = SubgroupLinkStore()
        self.subgroupFileStore = SubgroupFileStore()
        self.subgroupImageStore = SubgroupImageStore(subgroupId: subgroupStore.subgroup.id)
        self.studentDashboardStore = StudentDashboardStore(subgroupStore: subgroupStore, eventStore: eventStore)
        self.chatStore = ChatStore()
        self.activityStore = ActivityStore()
        self.registrationStore = RegistrationStore()
        self.attendanceStore = AttendanceStore()
        self.routingService = ApprovalFlowRoutingService()
        
        self.chatStore.eventStore = eventStore
        
        Task { @MainActor in
            await self.fetchOrganizationProfile()
            self.startOrganizationRealtimeSubscription()
        }
        
        startBackgroundPolling()
    }
    
    /// Starts a 5-second polling timer that silently syncs key data and feature flags from Supabase.
    private func startBackgroundPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
            guard let self = self else { return }
            Task { @MainActor in
                await self.fetchOrganizationProfile()
                if self.isLoggedIn {
                    await self.silentRefreshKeyData()
                }
            }
        }
    }
    
    private var orgChannel: RealtimeChannelV2?
    private var orgSubscriptionTask: Task<Void, Never>?

    @MainActor
    public func startOrganizationRealtimeSubscription() {
        guard orgChannel == nil else { return }
        orgSubscriptionTask?.cancel()
        
        let client = SupabaseManager.shared.client
        let channel = client.realtimeV2.channel("public:organizations")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "organizations"
        )
        
        orgSubscriptionTask = Task {
            await client.realtimeV2.connect()
            try? await channel.subscribeWithError()
            
            for await _ in changes {
                if Task.isCancelled { break }
                print("DEBUG: [AppSession] Realtime update detected on organizations table! Refreshing features...")
                await self.fetchOrganizationProfile()
            }
        }
        
        orgChannel = channel
        print("DEBUG: [AppSession] Organizations realtime subscription started")
    }

    @MainActor
    public func stopOrganizationRealtimeSubscription() {
        orgSubscriptionTask?.cancel()
        orgSubscriptionTask = nil
        if let channel = orgChannel {
            Task {
                await SupabaseManager.shared.client.realtimeV2.removeChannel(channel)
            }
        }
        orgChannel = nil
    }

    @MainActor
    public func fetchOrganizationProfile() async {
        do {
            var query = SupabaseManager.shared.client
                .from("organizations")
                .select()
            
            if let orgId = currentUser?.organizationId ?? currentUser?.instituteId {
                query = query.eq("id", value: orgId)
            }
            
            let fetchedOrgs: [OrganizationProfile] = try await query
                .limit(1)
                .execute()
                .value
            if let org = fetchedOrgs.first {
                self.organizationProfile = org
                print("DEBUG: [AppSession] Fetched org features from Supabase: \(String(describing: org.features))")
            }
        } catch {
            print("DEBUG ERROR: Failed to fetch organization profile: \(error)")
        }
    }

    /// Lightweight silent refresh that fetches only the frequently-changing tables
    /// (events, approvals, budgets, resources, tasks, chats) without showing any loading UI.
    @MainActor
    public func silentRefreshKeyData() async {
        guard isLoggedIn, let user = currentUser else { return }
        
        // Fetch key data in parallel including subgroups
        async let orgProfileTask: Void = { await self.fetchOrganizationProfile() }()
        async let eventsTask: Void = { try? await self.eventStore.fetchAllEvents() }()
        async let approvalsTask: Void = { try? await self.approvalStore.fetchApprovals() }()
        async let budgetsTask: Void = { try? await self.approvalStore.fetchBudgets() }()
        async let resourcesTask: Void = { try? await self.approvalStore.fetchResources() }()
        async let registrationsTask: Void = { try? await self.registrationStore.fetchRegistrations() }()
        async let tasksTask: Void = { try? await self.taskStore.fetchTasks() }()
        async let subgroupsTask: Void = { try? await self.subgroupStore.fetchAllSubgroups() }()
        async let hierarchyTask: Void = { try? await self.subgroupStore.fetchHierarchyLevels() }()
        async let usersTask: Void = { try? await self.subgroupStore.fetchAllUsers() }()
        
        // If user is affiliated with a subgroup, refresh details in parallel
        async let subgroupDetailsTask: Void = {
            if let subgroupId = user.subgroupId {
                try? await self.subgroupStore.fetchSubgroupDetails(id: subgroupId)
            }
        }()
        
        await orgProfileTask
        await eventsTask
        await approvalsTask
        await budgetsTask
        await resourcesTask
        await registrationsTask
        await tasksTask
        await subgroupsTask
        await hierarchyTask
        await usersTask
        await subgroupDetailsTask
        
        let userRegistrations = self.registrationStore.registrations.filter { $0.userId == user.id }
        self.registeredEventIds = Set(userRegistrations.compactMap { $0.eventId })
        self.studentDashboardStore.registeredEventIds = self.registeredEventIds
        
        for i in 0..<self.eventStore.events.count {
            let evId = self.eventStore.events[i].id
            let count = self.registrationStore.getRegistrations(for: evId).count
            if count > 0 || (self.eventStore.events[i].numberOfRegistrations ?? 0) < count {
                self.eventStore.events[i].numberOfRegistrations = count
            }
        }
        
        await chatStore.autoArchiveExpiredEventChats(events: eventStore.events)
        
        print("DEBUG: Silent background sync complete")
    }

    @MainActor
    public func restoreSession() async {
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
    public func signIn(user: User, role: AppRole) async {
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
    public func refreshData() async {
        guard isLoggedIn, let user = currentUser else { return }
        // Debounce: skip if already refreshing or if last refresh was less than 5 seconds ago
        guard !isRefreshing, Date().timeIntervalSince(lastRefreshDate) > 5 else {
            print("DEBUG: Skipping refresh (debounced)")
            return
        }
        isRefreshing = true
        lastRefreshDate = Date()
        
        print("DEBUG: Starting Data Refresh for \(user.name)...")
        
        // Refresh User profile to pick up any DB updates (like subgroup_id or role changes)
        do {
            let authService = SupabaseAuthService()
            let refreshedUser = try await authService.fetchUserProfile(userId: user.id)
            self.currentUser = refreshedUser
        } catch {
            print("DEBUG ERROR: Refreshed user profile failed: \(error)")
        }
        
        guard let activeUser = currentUser else {
            isRefreshing = false
            return
        }
        
        // 1. Fetch User's specific Subgroup Details FIRST
        if let subgroupId = activeUser.subgroupId {
            do {
                print("DEBUG: Loading personal subgroup data for \(subgroupId)")
                try await subgroupStore.fetchSubgroupDetails(id: subgroupId)
                print("DEBUG: Personal subgroup data loaded: \(subgroupStore.subgroup.name)")
            } catch {
                print("DEBUG ERROR: Personal subgroup data failed: \(error.localizedDescription)")
            }
            
            // Secondary fetches should not block main subgroup details
            do { try await subgroupAchievementStore.fetchAchievements(subgroupId: subgroupId) } catch { print("DEBUG ERROR: Fetch achievements failed: \(error)") }
            do { try await activityStore.fetchActivities(subgroupId: subgroupId) } catch { print("DEBUG ERROR: Fetch activities failed: \(error)") }
            do { try await subgroupFileStore.fetchFiles(subgroupId: subgroupId) } catch { print("DEBUG ERROR: Fetch files failed: \(error)") }
            do { try await subgroupLinkStore.fetchLinks(subgroupId: subgroupId) } catch { print("DEBUG ERROR: Fetch links failed: \(error)") }
            do { try await subgroupImageStore.fetchImages(subgroupId: subgroupId) } catch { print("DEBUG ERROR: Fetch images failed: \(error)") }
        }

        // 2. Load Global Data in parallel (Non-blocking)
        async let orgProfileTask: Void = { await self.fetchOrganizationProfile() }()
        async let subgroupsTask: Void = { do { try await subgroupStore.fetchAllSubgroups() } catch { print("DEBUG REFRESH ERROR: fetchAllSubgroups failed: \(error)") } }()
        async let usersTask: Void = { do { try await subgroupStore.fetchAllUsers() } catch { print("DEBUG REFRESH ERROR: fetchAllUsers failed: \(error)") } }()
        async let eventsTask: Void = { do { try await eventStore.fetchAllEvents() } catch { print("DEBUG REFRESH ERROR: fetchAllEvents failed: \(error)") } }()
        async let approvalsTask: Void = { do { try await approvalStore.fetchApprovals() } catch { print("DEBUG REFRESH ERROR: fetchApprovals failed: \(error)") } }()
        async let budgetsTask: Void = { do { try await approvalStore.fetchBudgets() } catch { print("DEBUG REFRESH ERROR: fetchBudgets failed: \(error)") } }()
        async let resourcesTask: Void = { do { try await approvalStore.fetchResources() } catch { print("DEBUG REFRESH ERROR: fetchResources failed: \(error)") } }()
        async let registrationsTask: Void = { do { try await registrationStore.fetchRegistrations() } catch { print("DEBUG REFRESH ERROR: fetchRegistrations failed: \(error)") } }()
        async let tasksTask: Void = { do { try await taskStore.fetchTasks() } catch { print("DEBUG REFRESH ERROR: fetchTasks failed: \(error)") } }()
        async let announcementsTask: Void = { do { try await announcementStore.fetchAnnouncements() } catch { print("DEBUG REFRESH ERROR: fetchAnnouncements failed: \(error)") } }()
        async let venuesTask: Void = { do { try await venueStore.fetchVenues() } catch { print("DEBUG REFRESH ERROR: fetchVenues failed: \(error)") } }()
        async let bookedSlotsTask: Void = { do { try await venueStore.fetchBookedSlots() } catch { print("DEBUG REFRESH ERROR: fetchBookedSlots failed: \(error)") } }()
        async let chatsTask: Void = { await chatStore.fetchChatsIfNeeded() }()
        async let hierarchyTask: Void = { do { try await subgroupStore.fetchHierarchyLevels() } catch { print("DEBUG REFRESH ERROR: fetchHierarchyLevels failed: \(error)") } }()
        
        await orgProfileTask
        await subgroupsTask
        await usersTask
        await eventsTask
        await approvalsTask
        await budgetsTask
        await resourcesTask
        await registrationsTask
        await tasksTask
        await announcementsTask
        await venuesTask
        await bookedSlotsTask
        await chatsTask
        await hierarchyTask
        
        await chatStore.autoArchiveExpiredEventChats(events: eventStore.events)
        await syncBookedSlotsForApprovedEvents()
        
        // 3. Sync registrations
        let userRegistrations = registrationStore.registrations.filter { $0.userId == user.id }
        self.registeredEventIds = Set(userRegistrations.compactMap { $0.eventId })
        self.studentDashboardStore.registeredEventIds = self.registeredEventIds
        
        for i in 0..<self.eventStore.events.count {
            let evId = self.eventStore.events[i].id
            let count = self.registrationStore.getRegistrations(for: evId).count
            if count > 0 || (self.eventStore.events[i].numberOfRegistrations ?? 0) < count {
                self.eventStore.events[i].numberOfRegistrations = count
            }
        }
        
        print("DEBUG: Data Sync Sequence Complete")
        print("DEBUG COUNTS: approvals=\(approvalStore.approvals.count), events=\(eventStore.events.count), budgets=\(approvalStore.budgets.count), resources=\(approvalStore.resources.count), user=\(activeUser.name), role=\(activeUser.role.rawValue), activeUserId=\(activeUser.id)")
        
        print("DEBUG: ALL Fetched Approvals:")
        for a in approvalStore.approvals {
            print("  - Approval \(a.id): type=\(a.type.rawValue), sender=\(a.senderId?.uuidString ?? "nil"), receiver=\(a.receiverId?.uuidString ?? "nil"), event=\(a.eventId?.uuidString ?? "nil"), status=\(a.status.rawValue)")
        }
        
        // Log pending approvals for this user specifically
        let myPendingReceived = approvalStore.approvals.filter { $0.receiverId == activeUser.id && $0.status == .pending }
        print("DEBUG: Pending approvals received by current user: \(myPendingReceived.count)")
        for a in myPendingReceived {
            print("  - Approval \(a.id): type=\(a.type.rawValue), sender=\(a.senderId?.uuidString ?? "nil"), event=\(a.eventId?.uuidString ?? "nil")")
        }
        isRefreshing = false
    }

    @MainActor
    public func signOut() {
        currentUser = nil
        currentRole = nil
        isLoggedIn = false
        registeredEventIds = []
        favouritedEventIds = []
        studentDashboardStore.registeredEventIds = []
        chatStore.stopRealtimeSubscription()
        chatStore.clearData()
        announcementStore.stopRealtimeSubscription()
        stopOrganizationRealtimeSubscription()
    }
    
    @MainActor
    public func updateUserProfile(name: String, bio: String, phoneNumber: String, course: String, year: String, admissionNumber: String, imageData: Data?) async throws {
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
            "admission_number": .string(admissionNumber),
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
        user.admissionNumber = admissionNumber
        user.profileImg = profileImgUrl
        user.imageData = nil // Clear local imageData so the view uses the remote URL
        currentUser = user
        
        // Sync with global users list
        subgroupStore.updateMember(updatedUser: user)
        
        // Refresh global users list from database so other views see the changes
        try? await subgroupStore.fetchAllUsers()
    }
    
    @MainActor
    public func registerForEvent(id: UUID, answers: [String: String]? = nil) async -> Bool {
        guard let userId = currentUser?.id else { return false }
        
        // Find the event to check max participants
        guard let event = eventStore.events.first(where: { $0.id == id }) else { return false }
        let currentCount = registrationStore.getRegistrations(for: id).count
        
        // First Come First Serve: Check if full before allowing new registration (Bypass for president)
        if currentUser?.role != .groupLead {
            if !registeredEventIds.contains(id) && event.maxParticipants > 0 && event.maxParticipants < 999999 && currentCount >= event.maxParticipants {
                print("Registration failed: Event is full")
                return false
            }
        }
        
        let isRegistering = !registeredEventIds.contains(id)
        
        do {
            try await registrationStore.toggleRegistration(eventId: id, userId: userId, answers: answers)
            
            let updatedCount = registrationStore.getRegistrations(for: id).count
            
            // Update registration count locally for immediate UI feedback
            if let index = eventStore.events.firstIndex(where: { $0.id == id }) {
                eventStore.events[index].numberOfRegistrations = updatedCount
                
                if isRegistering {
                    registeredEventIds.insert(id)
                    
                    // Add user to the event's General chat globally
                    print("DEBUG: [AppSession] Registering user \(userId) for event '\(event.title)' subgroupId=\(event.subgroupId?.uuidString ?? "nil")")
                    if let subgroupId = event.subgroupId {
                        await chatStore.addUserToEventChatsGlobally(userId: userId, eventId: id, eventTitle: event.title, subgroupId: subgroupId)
                    } else {
                        print("DEBUG: [AppSession] WARNING: event.subgroupId is nil, cannot add to chat")
                    }
                } else {
                    registeredEventIds.remove(id)
                    
                    // Remove user from the event's General chat globally
                    print("DEBUG: [AppSession] Withdrawing user \(userId) from event '\(event.title)' subgroupId=\(event.subgroupId?.uuidString ?? "nil")")
                    if let subgroupId = event.subgroupId {
                        await chatStore.removeUserFromEventChatsGlobally(userId: userId, eventId: id, eventTitle: event.title, subgroupId: subgroupId)
                    }
                }
            }
            
            studentDashboardStore.registeredEventIds = registeredEventIds
            
            // Persist updated count to events and group_events table in Supabase
            Task {
                try? await SupabaseManager.shared.client
                    .from("events")
                    .update(["number_of_registrations": updatedCount])
                    .eq("id", value: id)
                    .execute()
                try? await SupabaseManager.shared.client
                    .from("group_events")
                    .update(["number_of_registrations": updatedCount])
                    .eq("id", value: id)
                    .execute()
            }
            
            return true
        } catch {
            print("Registration toggle failed: \(error)")
            return false
        }
    }
    
    public func toggleFavorite(id: UUID) {
        if favouritedEventIds.contains(id) {
            favouritedEventIds.remove(id)
        } else {
            favouritedEventIds.insert(id)
        }
    }
    
    @MainActor
    public func checkAndAutoApproveEvent(eventId: UUID) async {
        let allResources = approvalStore.resources.filter { $0.eventId == eventId }
        let allBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
        
        let eventApprovals = approvalStore.approvals.filter { $0.eventId == eventId && $0.type == .event }
        let isEventApproved = !eventApprovals.isEmpty && eventApprovals.allSatisfy { $0.status == .approved }
        
        let isResourcesApproved = allResources.allSatisfy { $0.status == .approved }
        let isBudgetsApproved = allBudgets.allSatisfy { $0.status == .approved }
        
        let venueApprovals = approvalStore.approvals.filter { $0.eventId == eventId && $0.type == .venue }
        let isVenueApproved = venueApprovals.allSatisfy { $0.status == .approved }
        
        if isResourcesApproved && isBudgetsApproved && isVenueApproved && isEventApproved {
            try? await eventStore.updateEventStatus(id: eventId, status: .approved)
            
            if let event = eventStore.events.first(where: { $0.id == eventId }) {
                await chatStore.createEventChatsForPublishedEvent(event: event)
            }
            
            print("DEBUG Routing: Event \(eventId) is fully approved and live!")
        }
    }
    
    @MainActor
    public func forwardToEventsApproval(eventId: UUID, subgroup: Subgroup, senderId: UUID) async throws {
        let orgId = currentUser?.organizationId ?? currentUser?.instituteId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let approvers = await routingService.resolveApprovers(
            category: "Events",
            subgroupId: subgroup.id,
            groupId: subgroup.groupId,
            orgId: orgId
        )
        
        if approvers.isEmpty {
            // No Events approver configured, auto-approve and proceed to Budget
            let approvedEvent = Approval(
                id: UUID(),
                type: .event,
                senderId: senderId,
                receiverId: senderId,
                eventId: eventId,
                approvalRelatedId: eventId,
                status: .approved,
                remarks: [],
                createdAt: Date(),
                updatedAt: nil
            )
            try await approvalStore.submitApprovalRequests([approvedEvent])
            try await forwardToPresidentBudgetApproval(eventId: eventId, subgroup: subgroup, senderId: senderId)
            return
        }
        
        let firstApproverId = approvers.first!
        let eventApproval = Approval(
            id: UUID(),
            type: .event,
            senderId: senderId,
            receiverId: firstApproverId,
            eventId: eventId,
            approvalRelatedId: eventId,
            status: .pending,
            remarks: [],
            createdAt: Date(),
            updatedAt: nil
        )
        try await approvalStore.submitApprovalRequests([eventApproval])
    }
    
    @MainActor
    public func forwardToPresidentBudgetApproval(eventId: UUID, subgroup: Subgroup, senderId: UUID) async throws {
        let orgId = currentUser?.organizationId ?? currentUser?.instituteId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let approvers = await routingService.resolveApprovers(
            category: "Budget",
            subgroupId: subgroup.id,
            groupId: subgroup.groupId,
            orgId: orgId
        )
        
        let eventBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
        
        if eventBudgets.isEmpty || approvers.isEmpty {
            for budget in eventBudgets {
                try? await approvalStore.updateBudgetStatus(id: budget.id, status: .approved)
            }
            try await forwardToResourcesApproval(eventId: eventId, subgroup: subgroup, senderId: senderId)
            return
        }
        
        let firstApproverId = approvers.first!
        var approvalsToSave: [Approval] = []
        for budget in eventBudgets {
            let budgetApproval = Approval(
                id: UUID(),
                type: .budget,
                senderId: senderId,
                receiverId: firstApproverId,
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
    public func forwardToResourcesApproval(eventId: UUID, subgroup: Subgroup, senderId: UUID) async throws {
        let orgId = currentUser?.organizationId ?? currentUser?.instituteId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let eventResources = approvalStore.resources.filter { $0.eventId == eventId }
        
        let resourceApprovers = await routingService.resolveApprovers(
            category: "Resources",
            subgroupId: subgroup.id,
            groupId: subgroup.groupId,
            orgId: orgId
        )
        
        if eventResources.isEmpty || resourceApprovers.isEmpty {
            for resource in eventResources {
                try? await approvalStore.updateResourceStatus(id: resource.id, status: .approved)
            }
            try await forwardToVenueApproval(eventId: eventId, subgroup: subgroup, senderId: senderId)
            return
        }
        
        let firstApproverId = resourceApprovers.first!
        var approvalsToSave: [Approval] = []
        for resource in eventResources {
            let resApproval = Approval(
                id: UUID(),
                type: .resource,
                senderId: senderId,
                receiverId: firstApproverId,
                eventId: eventId,
                approvalRelatedId: resource.id,
                status: .pending,
                remarks: [],
                createdAt: Date(),
                updatedAt: nil
            )
            approvalsToSave.append(resApproval)
        }
        
        if !approvalsToSave.isEmpty {
            try await approvalStore.submitApprovalRequests(approvalsToSave)
        }
    }
    
    @MainActor
    public func forwardToVenueApproval(eventId: UUID, subgroup: Subgroup, senderId: UUID) async throws {
        let orgId = currentUser?.organizationId ?? currentUser?.instituteId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        
        guard let event = eventStore.events.first(where: { $0.id == eventId }) else {
            await checkAndAutoApproveEvent(eventId: eventId)
            return
        }
        
        let venueApprovers = await routingService.resolveApprovers(
            category: "Venue",
            subgroupId: subgroup.id,
            groupId: subgroup.groupId,
            orgId: orgId
        )
        
        let selectedVenue = venueStore.allVenues.first(where: { $0.name == event.location })
        let relatedId = selectedVenue?.id ?? eventId
        
        if venueApprovers.isEmpty {
            let approvedVenue = Approval(
                id: UUID(),
                type: .venue,
                senderId: senderId,
                receiverId: senderId,
                eventId: eventId,
                approvalRelatedId: relatedId,
                status: .approved,
                remarks: [],
                createdAt: Date(),
                updatedAt: nil
            )
            try await approvalStore.submitApprovalRequests([approvedVenue])
            await recordBookedSlot(eventId: eventId)
            await checkAndAutoApproveEvent(eventId: eventId)
            return
        }
        
        let firstApproverId = venueApprovers.first!
        let venueApproval = Approval(
            id: UUID(),
            type: .venue,
            senderId: senderId,
            receiverId: firstApproverId,
            eventId: eventId,
            approvalRelatedId: relatedId,
            status: .pending,
            remarks: [],
            createdAt: Date(),
            updatedAt: nil
        )
        try await approvalStore.submitApprovalRequests([venueApproval])
    }
    
    @MainActor
    public func forwardToEMTApproval(eventId: UUID, subgroup: Subgroup, senderId: UUID) async throws {
        // Kept for backward compatibility; routes straight to chronological sequential starting resource step
        try await forwardToResourcesApproval(eventId: eventId, subgroup: subgroup, senderId: senderId)
    }
    
    @MainActor
    public func processApprovalDecision(approval: Approval, status: ApprovalStatus) async throws {
        try await approvalStore.updateApproval(id: approval.id, status: status)
        
        guard let eventId = approval.eventId,
              let event = eventStore.events.first(where: { $0.id == eventId }),
              let subgroup = subgroupStore.allSubgroups.first(where: { $0.id == event.subgroupId }) else {
            return
        }
        
        let orgId = currentUser?.organizationId ?? currentUser?.instituteId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        
        if status == .rejected {
            if approval.type == .budget, let budgetId = approval.approvalRelatedId {
                try? await approvalStore.updateBudgetStatus(id: budgetId, status: .rejected)
            } else if approval.type == .resource, let resourceId = approval.approvalRelatedId {
                try? await approvalStore.updateResourceStatus(id: resourceId, status: .rejected)
            } else if approval.type == .event {
                try? await eventStore.updateEventStatus(id: eventId, status: .pending)
            }
            return
        }
        
        let category: String
        switch approval.type {
        case .event: category = "Events"
        case .budget: category = "Budget"
        case .resource: category = "Resources"
        case .venue: category = "Venue"
        }
        
        let approvers = await routingService.resolveApprovers(
            category: category,
            subgroupId: subgroup.id,
            groupId: subgroup.groupId,
            orgId: orgId
        )
        
        if let receiverId = approval.receiverId,
           let currentIndex = approvers.firstIndex(of: receiverId) {
            if currentIndex + 1 < approvers.count {
                let nextApproverId = approvers[currentIndex + 1]
                let nextApproval = Approval(
                    id: UUID(),
                    type: approval.type,
                    senderId: approval.senderId,
                    receiverId: nextApproverId,
                    eventId: eventId,
                    approvalRelatedId: approval.approvalRelatedId ?? eventId,
                    status: .pending,
                    remarks: [],
                    createdAt: Date(),
                    updatedAt: nil
                )
                try await approvalStore.submitApprovalRequests([nextApproval])
                print("DEBUG Routing: Forwarding \(approval.type.rawValue) approval to next level (approver: \(nextApproverId))")
                return
            }
        }
        
        print("DEBUG Routing: Category \(category) fully approved by sequential configuration.")
        
        if approval.type == .event {
            // Check if it is a VP draft approval
            if let vicePresidentId = subgroup.vicePresidentId, approval.receiverId == vicePresidentId {
                try await forwardToEventsApproval(
                    eventId: eventId,
                    subgroup: subgroup,
                    senderId: approval.senderId ?? currentUser?.id ?? UUID()
                )
            } else {
                // Configured Events category fully approved, forward to Budget
                try await forwardToPresidentBudgetApproval(
                    eventId: eventId,
                    subgroup: subgroup,
                    senderId: approval.senderId ?? currentUser?.id ?? UUID()
                )
            }
        } else if approval.type == .budget, let budgetId = approval.approvalRelatedId {
            try await approvalStore.updateBudgetStatus(id: budgetId, status: .approved)
            let eventBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
            let allBudgetsApproved = eventBudgets.allSatisfy { $0.status == .approved }
            if allBudgetsApproved {
                try await forwardToResourcesApproval(eventId: eventId, subgroup: subgroup, senderId: approval.senderId ?? currentUser?.id ?? UUID())
            }
        } else if approval.type == .resource, let resourceId = approval.approvalRelatedId {
            try await approvalStore.updateResourceStatus(id: resourceId, status: .approved)
            let eventResources = approvalStore.resources.filter { $0.eventId == eventId }
            let allResourcesApproved = eventResources.allSatisfy { $0.status == .approved }
            if allResourcesApproved {
                try await forwardToVenueApproval(eventId: eventId, subgroup: subgroup, senderId: approval.senderId ?? currentUser?.id ?? UUID())
            }
        } else if approval.type == .venue {
            if status == .approved {
                await recordBookedSlot(eventId: eventId)
            }
            await checkAndAutoApproveEvent(eventId: eventId)
        }
    }
    
    @MainActor
    public func approveBudgetAndCheckForwarding(budget: Budget, status: ApprovalStatus) async throws {
        if let approval = approvalStore.approvals.first(where: { $0.approvalRelatedId == budget.id && $0.status == .pending }) {
            try await processApprovalDecision(approval: approval, status: status)
        } else {
            try await approvalStore.updateBudgetStatus(id: budget.id, status: status)
            if status == .approved {
                guard let eventId = budget.eventId else { return }
                let eventBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
                let allApproved = eventBudgets.allSatisfy { $0.status == .approved }
                if allApproved {
                    if let event = eventStore.events.first(where: { $0.id == eventId }),
                       let subgroup = subgroupStore.allSubgroups.first(where: { $0.id == event.subgroupId }) {
                        try await forwardToResourcesApproval(eventId: eventId, subgroup: subgroup, senderId: currentUser?.id ?? UUID())
                    }
                }
            }
        }
    }
    
    @MainActor
    public func approveResourceAndCheckForwarding(resource: Resource, status: ApprovalStatus) async throws {
        if let approval = approvalStore.approvals.first(where: { $0.approvalRelatedId == resource.id && $0.status == .pending }) {
            try await processApprovalDecision(approval: approval, status: status)
        } else {
            try await approvalStore.updateResourceStatus(id: resource.id, status: ResourceStatus(rawValue: status.rawValue) ?? .pending)
            if status == .approved {
                guard let eventId = resource.eventId else { return }
                let eventResources = approvalStore.resources.filter { $0.eventId == eventId }
                let allApproved = eventResources.allSatisfy { $0.status == .approved }
                if allApproved {
                    if let event = eventStore.events.first(where: { $0.id == eventId }),
                       let subgroup = subgroupStore.allSubgroups.first(where: { $0.id == event.subgroupId }) {
                        try await forwardToVenueApproval(eventId: eventId, subgroup: subgroup, senderId: currentUser?.id ?? UUID())
                    }
                }
            }
        }
    }
    
    @MainActor
    public func recordBookedSlot(eventId: UUID) async {
        guard let event = eventStore.events.first(where: { $0.id == eventId }) else { return }
        guard let venue = venueStore.allVenues.first(where: { $0.name == event.location }) else { return }
        
        let newSlot = DBBookedSlot(
            id: UUID(),
            venueId: venue.id,
            eventId: event.id,
            subgroupId: event.subgroupId,
            startTime: event.startDate,
            endTime: event.endDate,
            createdAt: Date()
        )
        
        do {
            try await SupabaseManager.shared.client
                .from("booked_slots")
                .insert(newSlot)
                .execute()
            print("DEBUG: Recorded booked slot successfully.")
            try? await venueStore.fetchBookedSlots()
        } catch {
            print("DEBUG ERROR: Failed to record booked slot: \(error)")
        }
    }
    
    @MainActor
    public func syncBookedSlotsForApprovedEvents() async {
        let currentSlots = venueStore.bookedSlots
        let approvedEvents = eventStore.events.filter { $0.status == .approved || $0.status == .published }
        
        for event in approvedEvents {
            if !currentSlots.contains(where: { $0.eventId == event.id }) {
                if let venue = venueStore.allVenues.first(where: { $0.name == event.location }) {
                    let newSlot = DBBookedSlot(
                        id: UUID(),
                        venueId: venue.id,
                        eventId: event.id,
                        subgroupId: event.subgroupId,
                        startTime: event.startDate,
                        endTime: event.endDate,
                        createdAt: Date()
                    )
                    do {
                        try await SupabaseManager.shared.client
                            .from("booked_slots")
                            .insert(newSlot)
                            .execute()
                        print("DEBUG SYNC: Auto-recorded booked slot for event \(event.name)")
                    } catch {
                        print("DEBUG SYNC ERROR: Failed to auto-record: \(error)")
                    }
                }
            }
        }
        try? await venueStore.fetchBookedSlots()
    }
}
