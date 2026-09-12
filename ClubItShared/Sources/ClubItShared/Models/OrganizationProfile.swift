import Foundation

public struct OrganizationSocials: Codable, Hashable, Sendable {
    public var discord: String?
    public var facebook: String?
    public var linkedin: String?
    public var whatsapp: String?
    public var instagram: String?
    
    public init(
        discord: String? = nil,
        facebook: String? = nil,
        linkedin: String? = nil,
        whatsapp: String? = nil,
        instagram: String? = nil
    ) {
        self.discord = discord
        self.facebook = facebook
        self.linkedin = linkedin
        self.whatsapp = whatsapp
        self.instagram = instagram
    }
}

public struct OrganizationFeatures: Codable, Hashable, Sendable {
    public var chat: Bool?
    public var events: Bool?
    public var tasks: Bool?
    public var budget: Bool?
    public var announcements: Bool?
    public var attendance: Bool?
    public var achievements: Bool?
    public var venue: Bool?
    
    public init(
        chat: Bool? = nil,
        events: Bool? = nil,
        tasks: Bool? = nil,
        budget: Bool? = nil,
        announcements: Bool? = nil,
        attendance: Bool? = nil,
        achievements: Bool? = nil,
        venue: Bool? = nil
    ) {
        self.chat = chat
        self.events = events
        self.tasks = tasks
        self.budget = budget
        self.announcements = announcements
        self.attendance = attendance
        self.achievements = achievements
        self.venue = venue
    }
    
    // MARK: - Helper Methods (true = Disabled, false/nil = Enabled)
    public var isChatDisabled: Bool { chat == true }
    public var isEventsDisabled: Bool { events == true }
    public var isTasksDisabled: Bool { tasks == true }
    public var isBudgetDisabled: Bool { budget == true }
    public var isAnnouncementsDisabled: Bool { announcements == true }
    public var isAttendanceDisabled: Bool { attendance == true }
    public var isAchievementsDisabled: Bool { achievements == true }
    public var isVenueDisabled: Bool { venue == true }
    
    // MARK: - Explore Tab Helpers
    public var isExploreVisible: Bool {
        !isEventsDisabled || !isAnnouncementsDisabled
    }
    
    public var exploreTabTitle: String {
        if !isEventsDisabled && !isAnnouncementsDisabled {
            return "Explore"
        } else if !isAnnouncementsDisabled {
            return "Announcements"
        } else {
            return "Events"
        }
    }
    
    public var exploreTabIcon: String {
        if !isEventsDisabled && !isAnnouncementsDisabled {
            return "globe"
        } else if !isAnnouncementsDisabled {
            return "megaphone"
        } else {
            return "calendar"
        }
    }
}

public struct OrganizationProfile: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let domain: String?
    public let logoUrl: String?
    public let socials: OrganizationSocials?
    public let features: OrganizationFeatures?
    
    public init(
        id: UUID,
        name: String,
        domain: String? = nil,
        logoUrl: String? = nil,
        socials: OrganizationSocials? = nil,
        features: OrganizationFeatures? = nil
    ) {
        self.id = id
        self.name = name
        self.domain = domain
        self.logoUrl = logoUrl
        self.socials = socials
        self.features = features
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case domain
        case logoUrl = "logo_url"
        case socials
        case features
    }
}
