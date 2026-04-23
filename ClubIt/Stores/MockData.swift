import Foundation

struct MockData {
    static let instituteId = UUID()

    struct MockClubBundle {
        let club: Club
        let users: [User]
        let events: [Event]
        let announcements: [Announcement]
    }

    static let technoJamBundle: MockClubBundle = {
        let clubId = UUID()
        let leadId = UUID()
        let facultyId = UUID(uuidString: "FAC11111-1111-1111-1111-111111111111")!
        let club = Club(
            id: clubId,
            name: "Technojam",
            tagLine: "Shaping future tech leaders through innovation",
            description: "Technojam is a community of passionate individuals dedicated to exploring and creating innovative technological solutions.",
            category: .technical,
            logo: "technojam_logo",
            clubLeadId: leadId,
            facultyId: facultyId,
            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 215,
            eventCount: 12,
            socials: ["instagram": "https://instagram.com/technojam"]
        )
        
        let users = [
            User(id: leadId, email: "tjlead", password: "pass123", name: "Aryan", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "B.Tech CSE", year: "3rd Year", bio: "TechnoJam club leader | UI designer", createdAt: Date(), status: .active),
            User(id: UUID(), email: "tjm1", password: "pass123", name: "Shivam", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Tech enthusiast.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "tjm2", password: "pass123", name: "Mayank", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Web developer", createdAt: Date(), status: .active),
            User(id: facultyId, email: "tjfac", password: "pass123", name: "Dr Sharma", instituteId: instituteId, role: .faculty, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "Faculty", year: "Senior Prof.", bio: "Guiding innovators.", createdAt: Date(), status: .active)
        ]
        
        let events = [
            Event(id: UUID(), name: "Tech Summit", title: "Annual Tech Summit 2025", description: "A grand gathering of technology enthusiasts.", startDate: Date().addingTimeInterval(3600 * 24 * 3), endDate: Date().addingTimeInterval(3600 * 24 * 3 + 3600 * 8), startTime: Date(), endTime: Date(), numberOfVolunteers: 10, numberOfRegistrations: 50, maxParticipants: 100, registrationType: .individual, location: "New Auditorium", clubId: clubId, createdBy: leadId, category: .technical, status: .pending, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 2), bannerImage: "banner1", agenda: "Opening keynote, Workshops", createdAt: Date())
        ]
        
        let announcements = [
            Announcement(clubId: clubId, date: Date(), title: "Tech Summit 2024 - Registration Open!", content: "Registration for our annual Tech Summit is now open.", url: "https://technojam.com/summit", postedBy: leadId, target: .club, createdAt: Date().addingTimeInterval(-7200))
        ]
        
        return MockClubBundle(club: club, users: users, events: events, announcements: announcements)
    }()

    static let lingoFreaksBundle: MockClubBundle = {
        let clubId = UUID()
        let leadId = UUID()
        let facultyId = UUID(uuidString: "FAC22222-2222-2222-2222-222222222222")!
        let club = Club(
            id: clubId,
            name: "Lingo Freaks",
            tagLine: "Beyond Borders, Beyond Languages",
            description: "One Club. Many Voices. Literary & Language society.",
            category: .literary,
            logo: "literary_logo",
            clubLeadId: leadId,
            facultyId: facultyId,
            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 85,
            eventCount: 4,
            socials: ["instagram": "https://instagram.com/lingofreaks"]
        )
        
        let users = [
            User(id: leadId, email: "lflead", password: "pass123", name: "Kavya", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "B.A. English", year: "3rd Year", bio: "Literature lover.", createdAt: Date(), status: .active),
            User(id: facultyId, email: "lffac", password: "pass123", name: "Prof. Das", instituteId: instituteId, role: .faculty, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "Faculty", year: "Associate Prof.", bio: "Language expert.", createdAt: Date(), status: .active)
        ]
        
        let events = [
            Event(id: UUID(), name: "Music Night", title: "Euphoria 2025", description: "Cultural event.", startDate: Date().addingTimeInterval(3600 * 24 * 7), endDate: Date().addingTimeInterval(3600 * 24 * 7 + 3600 * 4), startTime: Date(), endTime: Date(), numberOfVolunteers: 5, numberOfRegistrations: 150, maxParticipants: 300, registrationType: .individual, location: "New Auditorium", clubId: clubId, createdBy: leadId, category: .entertainment, status: .upcoming, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 6), bannerImage: "banner2", agenda: "Performances", createdAt: Date()),
            Event(id: UUID(), name: "Debate Night", title: "Speak Up 2025", description: "Literary debate competition.", startDate: Date().addingTimeInterval(3600 * 24 * 10), endDate: Date().addingTimeInterval(3600 * 24 * 10 + 3600 * 3), startTime: Date(), endTime: Date(), numberOfVolunteers: 5, numberOfRegistrations: 40, maxParticipants: 100, registrationType: .individual, location: "A101", clubId: clubId, createdBy: leadId, category: .literary, status: .upcoming, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 9), bannerImage: "banner1", agenda: "Debate rounds", createdAt: Date())
        ]
        
        return MockClubBundle(club: club, users: users, events: events, announcements: [])
    }()

    static let eCellBundle: MockClubBundle = {
        let clubId = UUID()
        let leadId = UUID()
        let club = Club(
            id: clubId,
            name: "E-cell",
            tagLine: "Innovation & Entrepreneurship",
            description: "Where innovative ideas transform into impactful ventures.",
            category: .entrepreneurship,
            logo: "ecell_logo",
            clubLeadId: leadId,
            facultyId: UUID(),
            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 120,
            eventCount: 8,
            socials: ["linkedin": "https://linkedin.com/company/ecell"]
        )
        
        let users = [
            User(id: leadId, email: "eclead", password: "pass123", name: "Ishaan", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "MBA", year: "2nd Year", bio: "Entrepreneurial spirit.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "ecfac", password: "pass123", name: "Dr. Verma", instituteId: instituteId, role: .faculty, clubId: clubId, profileImg: "", phoneNumber: "0000000000", course: "Faculty", year: "Dept Head", bio: "Nurturing entrepreneurship.", createdAt: Date(), status: .active)
        ]
        
        let events = [
            Event(id: UUID(), name: "Startup Pitch", title: "Idea Tank 2025", description: "Pitch your ideas to investors.", startDate: Date().addingTimeInterval(3600 * 24 * 15), endDate: Date().addingTimeInterval(3600 * 24 * 15 + 3600 * 5), startTime: Date(), endTime: Date(), numberOfVolunteers: 10, numberOfRegistrations: 20, maxParticipants: 50, registrationType: .individual, location: "Old Auditorium", clubId: clubId, createdBy: leadId, category: .entrepreneurship, status: .upcoming, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 14), bannerImage: "banner2", agenda: "Pitching rounds", createdAt: Date())
        ]
        
        return MockClubBundle(club: club, users: users, events: events, announcements: [])
    }()

    static let quizzardsBundle: MockClubBundle = {
        let clubId = UUID()
        let leadId = UUID()
        let club = Club(
            id: clubId,
            name: "Quizzards",
            tagLine: "Challenge your mind",
            description: "The ultimate destination for trivia lovers.",
            category: .technical,
            logo: "quizzards_logo",
            clubLeadId: leadId,
            facultyId: UUID(),
            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 150,
            eventCount: 15,
            socials: ["discord": "https://discord.gg/quizzards"]
        )
        
        let users = [
            User(id: leadId, email: "qzlead", password: "pass123", name: "Aditi", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "", phoneNumber: "+91 11111 22222", course: "B.Tech IT", year: "4th Year", bio: "Quizzer.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "qzfac", password: "pass123", name: "Prof. Iyer", instituteId: instituteId, role: .faculty, clubId: clubId, profileImg: "", phoneNumber: "+91 44444 55555", course: "Faculty", year: "Professor", bio: "Lifelong learner.", createdAt: Date(), status: .active)
        ]
        
        return MockClubBundle(club: club, users: users, events: [], announcements: [])
    }()

    // MARK: - Collections
    static let allBundles = [technoJamBundle, lingoFreaksBundle, eCellBundle, quizzardsBundle]

    static let allClubs: [Club] = allBundles.map { $0.club }

    static let allMockUsers: [User] = {
        var users = allBundles.flatMap { $0.users }
        
        // Add President & Vice President
        let presidentId = UUID()
        let vicePresidentId = UUID()
        users.append(User(id: presidentId, email: "president", password: "pass123", name: "Dr. Arun Mehra", instituteId: instituteId, role: .president, clubId: nil, profileImg: "", phoneNumber: "+91 99911 22233", course: "Administration", year: "N/A", bio: "University President", createdAt: Date(), status: .active))
        users.append(User(id: vicePresidentId, email: "vicepresident", password: "pass123", name: "Dr. Sunil Gupta", instituteId: instituteId, role: .vicePresident, clubId: nil, profileImg: "", phoneNumber: "+91 99911 22244", course: "Administration", year: "N/A", bio: "University Vice President", createdAt: Date(), status: .active))
        
        // Add general student
        users.append(User(id: UUID(), email: "student", password: "pass123", name: "Kamakshi", instituteId: instituteId, role: .student, clubId: nil, profileImg: "", phoneNumber: "+91 12345 67890", course: "B.Tech CSE", year: "3rd Year", bio: "Passionate builder.", createdAt: Date(), status: .active))
        return users
    }()

    static let sampleEvents: [Event] = allBundles.flatMap { $0.events }
    
    static let sampleAnnouncements: [Announcement] = allBundles.flatMap { $0.announcements }

    static let technoJamClub = technoJamBundle.club
    static let lingoFreaksClub = lingoFreaksBundle.club
    static let eCellClub = eCellBundle.club
    static let quizzardsClub = quizzardsBundle.club
    
    static let tj_id = technoJamBundle.club.id
    static let lf_id = lingoFreaksBundle.club.id
    static let ec_id = eCellBundle.club.id
    static let qz_id = quizzardsBundle.club.id

    static let clubLeadUser = allMockUsers.first { $0.role == .clubLead } ?? allMockUsers.first ?? placeholderUser
    static let facultyResource = allMockUsers.first { $0.email == "tjfac" } ?? allMockUsers.first ?? placeholderUser
    static let facultyVenue = allMockUsers.first { $0.email == "lffac" } ?? allMockUsers.first ?? placeholderUser
    static let studentUser = allMockUsers.first { $0.role == .student } ?? allMockUsers.first ?? placeholderUser
    
    static let placeholderUser = User(id: UUID(), email: "placeholder", password: "...", name: "User", instituteId: instituteId, role: .student, clubId: nil, profileImg: "", phoneNumber: "", course: "", year: "", bio: "", createdAt: Date(), status: .active)

    static let sampleApprovals: [Approval] = {
        let techSummitId = sampleEvents.first { $0.title.contains("Annual Tech Summit") }?.id ?? UUID()
        let musicNightId = sampleEvents.first { $0.title.contains("Euphoria") }?.id ?? UUID()
        let leadId = clubLeadUser.id
        
        return [
            Approval(id: UUID(), type: .resource, senderId: leadId, receiverId: facultyResource.id, eventId: techSummitId, approvalRelatedId: techSummitId, status: .pending, remark: nil, createdAt: Date().addingTimeInterval(-7200), updatedAt: Date()),
            Approval(id: UUID(), type: .budget, senderId: leadId, receiverId: facultyResource.id, eventId: musicNightId, approvalRelatedId: UUID(), status: .pending, remark: nil, createdAt: Date().addingTimeInterval(-3600), updatedAt: Date()),
            Approval(id: UUID(), type: .venue, senderId: leadId, receiverId: facultyVenue.id, eventId: techSummitId, approvalRelatedId: techSummitId, status: .pending, remark: nil, createdAt: Date().addingTimeInterval(-86400), updatedAt: Date())
        ]
    }()

    static let sampleResources: [Resource] = {
        let techSummitId = sampleEvents.first { $0.title.contains("Annual Tech Summit") }?.id ?? UUID()
        let musicNightId = sampleEvents.first { $0.title.contains("Euphoria") }?.id ?? UUID()
        let startupPitchId = sampleEvents.first { $0.title.contains("Idea Tank") }?.id ?? UUID()
        
        let leadId = clubLeadUser.id
        
        return [
            // Technojam University Resources
            Resource(id: UUID(), eventId: techSummitId, name: "Projectors", quantity: 5, type: .university, status: .pending, addedBy: leadId, createdAt: Date().addingTimeInterval(-172800)),
            Resource(id: UUID(), eventId: techSummitId, name: "Extension Boards", quantity: 10, type: .university, status: .approved, addedBy: leadId, createdAt: Date().addingTimeInterval(-86400)),
            
            // Lingo Freaks External Rentals
            Resource(id: UUID(), eventId: musicNightId, name: "Concert Stage Lights", quantity: 12, type: .external, status: .pending, cost: 15000, vendorName: "Bright Events", addedBy: leadId, createdAt: Date().addingTimeInterval(-129600)),
            Resource(id: UUID(), eventId: musicNightId, name: "Professional Sound System", quantity: 1, type: .external, status: .pending, cost: 25000, vendorName: "Echo Pro Audio", addedBy: leadId, createdAt: Date().addingTimeInterval(-86400)),
            Resource(id: UUID(), eventId: musicNightId, name: "Plastic Chairs", quantity: 200, type: .external, status: .approved, cost: 2000, vendorName: "Local Rentals", addedBy: leadId, createdAt: Date().addingTimeInterval(-43200)),
            
            // Technojam External Rentals
            Resource(id: UUID(), eventId: techSummitId, name: "Premium Catering", quantity: 50, type: .external, status: .pending, cost: 35000, vendorName: "Gourmet Hub", addedBy: leadId, createdAt: Date().addingTimeInterval(-259200)),
            
            // E-Cell University Resources
            Resource(id: UUID(), eventId: startupPitchId, name: "Movable Whiteboards", quantity: 4, type: .university, status: .pending, addedBy: leadId, createdAt: Date().addingTimeInterval(-72000))
        ]
    }()

    
    static func session(for email: String) -> AppSession {
        let session = AppSession()
        if let user = allMockUsers.first(where: { $0.email == email }) {
            session.currentUser = user
            session.currentRole = user.role
        } else {
            session.currentUser = studentUser
            session.currentRole = .student
        }
        return session
    }
    
    static func session(for role: AppRole) -> AppSession {
        let session = AppSession()
        session.currentRole = role
        if let user = allMockUsers.first(where: { $0.role == role }) {
            session.currentUser = user
        } else {
            session.currentUser = studentUser
        }
        return session
    }
}
