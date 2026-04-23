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
    
    var registeredEventIds: Set<UUID> = []

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
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    func signIn(user: User, role: AppRole) {
        currentUser = user
        currentRole = role
        isLoggedIn = true
        
        if let clubId = user.clubId {
            if let userClub = clubStore.allClubs.first(where: { $0.id == clubId }) {
                clubStore.club = userClub
            }
        }
    }

    func signOut() {
        currentUser = nil
        currentRole = nil
        isLoggedIn = false
    }
    
    func registerForEvent(id: UUID) {
        if registeredEventIds.contains(id) {
            registeredEventIds.remove(id)
        } else {
            registeredEventIds.insert(id)
        }
        studentDashboardStore.registeredEventIds = registeredEventIds
    }
}
