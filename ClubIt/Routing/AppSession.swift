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
    
    var activeDashboardTab: Int = 0
    var activeExploreTab: Int = 0
    
    var clubAchievementStore: AchievementStore
    var clubAnnouncementStore: ClubAnnouncementStore
    var globalAnnouncementStore: AnnouncementStore
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
        self.clubAnnouncementStore = ClubAnnouncementStore()
        self.globalAnnouncementStore = AnnouncementStore()
        self.clubLinkStore = ClubLinkStore(clubId: clubStore.club.id)
        self.clubFileStore = ClubFileStore(clubId: clubStore.club.id)
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
        print("DEBUG: Starting Data Refresh...")
        
        // 1. Fetch Clubs
        do {
            try await clubStore.fetchAllClubs()
            print("DEBUG: Clubs Fetched Successfully")
        } catch {
            print("DEBUG ERROR: Clubs Fetch Failed: \(error)")
        }
        
        // 2. Fetch Users
        do {
            try await clubStore.fetchAllUsers()
            print("DEBUG: Users Fetched Successfully")
        } catch {
            print("DEBUG ERROR: Users Fetch Failed: \(error)")
        }
        
        // 3. Fetch Events
        do {
            try await eventStore.fetchAllEvents()
            print("DEBUG: Events Fetched Successfully")
        } catch {
            print("DEBUG ERROR: Events Fetch Failed: \(error)")
        }
        
        // 4. User Specific Data
        if let clubId = currentUser?.clubId {
            do {
                try await clubStore.fetchClubDetails(id: clubId)
                try await activityStore.fetchActivities(clubId: clubId)
                print("DEBUG: User Specific Data Fetched")
            } catch {
                print("DEBUG ERROR: User Specific Fetch Failed: \(error)")
            }
        }
        
        // Sync registrations
        let userRegistrations = registrationStore.registrations.filter { $0.userId == currentUser?.id }
        registeredEventIds = Set(userRegistrations.map { $0.eventId })
        studentDashboardStore.registeredEventIds = registeredEventIds
        
        print("DEBUG: Data Sync Sequence Complete")
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
    
    func registerForEvent(id: UUID) {
        guard let userId = currentUser?.id else { return }
        
        // Find the event to check max participants
        guard let event = eventStore.events.first(where: { $0.id == id }) else { return }
        let currentCount = registrationStore.getRegistrations(for: id).count
        
        // First Come First Serve: Check if full before allowing new registration
        if !registeredEventIds.contains(id) && currentCount >= event.maxParticipants {
            print("Registration failed: Event is full")
            return
        }
        
        registrationStore.toggleRegistration(eventId: id, userId: userId)
        
        if registeredEventIds.contains(id) {
            registeredEventIds.remove(id)
        } else {
            registeredEventIds.insert(id)
        }
        studentDashboardStore.registeredEventIds = registeredEventIds
    }
    
    func toggleFavorite(id: UUID) {
        if favouritedEventIds.contains(id) {
            favouritedEventIds.remove(id)
        } else {
            favouritedEventIds.insert(id)
        }
    }
    
    func checkAndAutoApproveEvent(eventId: UUID) {
        let allResources = approvalStore.resources.filter { $0.eventId == eventId }
        let allVenues = approvalStore.approvals.filter { $0.eventId == eventId && $0.type == .venue }
        let allBudgets = approvalStore.budgets.filter { $0.eventId == eventId }
        
        let isFullyApproved = allResources.allSatisfy { $0.status == .approved } &&
                             allVenues.allSatisfy { $0.status == .approved } &&
                             allBudgets.allSatisfy { $0.status == .approved }
        
        if isFullyApproved {
            if let eventApproval = approvalStore.approvals.first(where: { $0.eventId == eventId && $0.type == .event && $0.status == .pending }) {
                approvalStore.updateApproval(id: eventApproval.id, status: .approved)
            }
            eventStore.updateEventStatus(id: eventId, status: .upcoming)
        }
    }
}
