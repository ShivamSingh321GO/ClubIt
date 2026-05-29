import Foundation

struct MockData {
    static let instituteId = UUID()
    
    // Static IDs for Council
    static let presidentId = UUID(uuidString: "db2cc487-3f38-473c-893c-20e352dfdd6b")!
    static let vpTechId = UUID()
    static let vpLitId = UUID()
    static let vpBizId = UUID()
    static let eventManagementFacultyId = UUID()
    static let unassignedVPId = UUID()


    struct MockClubBundle {
        let club: Club
        let users: [User]
        let events: [Event]
        let announcements: [Announcement]
    }

    static let technoJamBundle: MockClubBundle = {
        let clubId = UUID()
        let leadId = UUID()
        let facultyId = eventManagementFacultyId
        let club = Club(
            id: clubId,
            name: "Technojam",
            tagLine: "Shaping future tech leaders through innovation",
            description: "Technojam is a community of passionate individuals dedicated to exploring and creating innovative technological solutions.",
            category: .technical,
            logo: "technojamLogo",
            clubLeadId: leadId,
            facultyId: facultyId,

            vicePresidentId: vpTechId,

//            vicePresidentId: nil,

            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 45,
            eventCount: 12,
            socials: [
                "instagram": "https://instagram.com/",
                "facebook": "https://facebook.com/",
                "linkedin": "https://linkedin.com/company/",
                "discord": "https://discord.gg/",
                "whatsapp": "https://wa.me/"
            ]
        )
        
        let users = [
            User(id: leadId, email: "tjlead", name: "Aryan", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "3rd Year", bio: "TechnoJam club leader | UI designer", createdAt: Date(), status: .active),
            User(id: UUID(), email: "tjm1", name: "Shivam", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Tech enthusiast.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "tjm2", name: "Mayank", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Web developer", createdAt: Date(), status: .active),
            User(id: UUID(), email: "tjm3", name: "Rohan", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "3nd Year", bio: "Web developer", createdAt: Date(), status: .active)
        ]
        
        let events = [
            Event(id: UUID(), name: "Tech Summit", title: "Annual Tech Summit 2025", description: "A grand gathering of technology enthusiasts.", startDate: Date().addingTimeInterval(3600 * 24 * 3), endDate: Date().addingTimeInterval(3600 * 24 * 3 + 3600 * 8), startTime: Date(), endTime: Date(), numberOfVolunteers: 10, numberOfRegistrations: 0, maxParticipants: 100, registrationType: .individual, location: "New Auditorium", clubId: clubId, createdBy: leadId, category: .technical, status: .pending, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 2), bannerImage: "banner1", agenda: "Opening keynote, Workshops", createdAt: Date()),
            
            Event(id: UUID(), name: "Web Dev Workshop", title: "Modern Web Development", description: "Learn React and Tailwind in this hands-on workshop.", startDate: Date().addingTimeInterval(3600 * 24 * 5), endDate: Date().addingTimeInterval(3600 * 24 * 5 + 3600 * 3), startTime: Date(), endTime: Date(), numberOfVolunteers: 5, numberOfRegistrations: 0, maxParticipants: 30, registrationType: .team, location: "Lab 3", clubId: clubId, createdBy: leadId, category: .technical, status: .approved, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 4), bannerImage: "banner1", agenda: "Intro, React Basics, Deployment", 
                registrationForm: [
                    RegistrationFormField(id: UUID(), label: "Full Name", type: .text),
                    RegistrationFormField(id: UUID(), label: "Student ID", type: .text),
                    RegistrationFormField(id: UUID(), label: "Proficiency in JavaScript", type: .multipleChoice, options: ["None", "Beginner", "Advanced"]),
                    RegistrationFormField(id: UUID(), label: "Why do you want to join?", type: .paragraph),
                    RegistrationFormField(id: UUID(), label: "Dietary Preferences", type: .checkbox, options: ["Veg", "Non-Veg", "Vegan"])
                ],
                createdAt: Date()),
            
            Event(id: UUID(), name: "AI Workshop 2025", title: "AI Workshop 2025", description: "Hands-on workshop on generative AI.", startDate: Date().addingTimeInterval(3600 * 24 * 7), endDate: Date().addingTimeInterval(3600 * 24 * 7 + 3600 * 4), startTime: Date(), endTime: Date(), numberOfVolunteers: 5, numberOfRegistrations: 0, maxParticipants: 50, registrationType: .individual, location: "Lab 5", clubId: clubId, createdBy: leadId, category: .ai, status: .approved, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 6), bannerImage: "banner1", agenda: "Intro, GenAI, Practical Lab", createdAt: Date())
        ]
        
        let announcements = [
            Announcement(id: UUID(), clubId: clubId, date: Date(), title: "Tech Summit 2024", content: "Registration for our annual Tech Summit is now open.", url: "https://technojam.com/summit", postedBy: leadId, createdAt: Date().addingTimeInterval(-7200))
        ]
        
        return MockClubBundle(club: club, users: users, events: events, announcements: announcements)
    }()

    static let lingoFreaksBundle: MockClubBundle = {
        let clubId = UUID()
        let leadId = UUID()
        let facultyId = eventManagementFacultyId
        let club = Club(
            id: clubId,
            name: "Lingo Freaks",
            tagLine: "Beyond Borders, Beyond Languages",
            description: "One Club. Many Voices. Literary & Language society.",
            category: .literary,
            logo: "lingofreaksLogo",
            clubLeadId: leadId,
            facultyId: facultyId,

            vicePresidentId: vpLitId,

//            vicePresidentId: nil,

            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 25,
            eventCount: 4,
            socials: [
                "instagram": "https://instagram.com/",
                "facebook": "https://facebook.com/",
                "linkedin": "https://linkedin.com/company/",
                "discord": "https://discord.gg/",
                "whatsapp": "https://wa.me/"
            ]
        )
        
        let users = [
            User(id: leadId, email: "lflead", name: "Kavya", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.A. English", year: "3rd Year", bio: "Literature lover.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "lfm1", name: "Rohan", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Tech enthusiast.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "lfm2", name: "Rishi", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Tech enthusiast.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "lfm3", name: "Isha", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "Tech enthusiast.", createdAt: Date(), status: .active)
        ]
        
        let events = [
            Event(id: UUID(), name: "Music Night", title: "Euphoria 2025", description: "Cultural event.", startDate: Date().addingTimeInterval(3600 * 24 * 7), endDate: Date().addingTimeInterval(3600 * 24 * 7 + 3600 * 4), startTime: Date(), endTime: Date(), numberOfVolunteers: 5, numberOfRegistrations: 0, maxParticipants: 300, registrationType: .individual, location: "New Auditorium", clubId: clubId, createdBy: leadId, category: .entertainment, status: .approved, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 6), bannerImage: "banner2", agenda: "Performances", createdAt: Date()),
            Event(id: UUID(), name: "Debate Night", title: "Speak Up 2025", description: "Literary debate competition.", startDate: Date().addingTimeInterval(3600 * 24 * 10), endDate: Date().addingTimeInterval(3600 * 24 * 10 + 3600 * 3), startTime: Date(), endTime: Date(), numberOfVolunteers: 5, numberOfRegistrations: 0, maxParticipants: 100, registrationType: .individual, location: "A101", clubId: clubId, createdBy: leadId, category: .literary, status: .approved, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 9), bannerImage: "banner1", agenda: "Debate rounds", createdAt: Date())
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
            logo: "ecellLogo",
            clubLeadId: leadId,
            facultyId: eventManagementFacultyId,
            vicePresidentId: vpBizId,
//            vicePresidentId: nil,
            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 20,
            eventCount: 8,
            socials: [
                "instagram": "https://instagram.com/",
                "facebook": "https://facebook.com/",
                "linkedin": "https://linkedin.com/company/",
                "discord": "https://discord.gg/",
                "whatsapp": "https://wa.me/"
            ]
        )
        
        let users = [
            User(id: leadId, email: "eclead", name: "Ishaan", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "MBA", year: "2nd Year", bio: "Entrepreneurial spirit.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "ecm1", name: "Saanvi", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "MBA", year: "2nd Year", bio: "Entrepreneurial spirit.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "ecm2", name: "Siddharth", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "MBA", year: "2nd Year", bio: "Entrepreneurial spirit.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "ecm3", name: "Vihaan", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "MBA", year: "2nd Year", bio: "Entrepreneurial spirit.", createdAt: Date(), status: .active)
        ]
        
        let events = [
            Event(id: UUID(), name: "Startup Pitch", title: "Idea Tank 2025", description: "Pitch your ideas to investors.", startDate: Date().addingTimeInterval(3600 * 24 * 15), endDate: Date().addingTimeInterval(3600 * 24 * 15 + 3600 * 5), startTime: Date(), endTime: Date(), numberOfVolunteers: 10, numberOfRegistrations: 0, maxParticipants: 50, registrationType: .individual, location: "Old Auditorium", clubId: clubId, createdBy: leadId, category: .entrepreneurship, status: .approved, registrationDeadline: Date().addingTimeInterval(3600 * 24 * 14), bannerImage: "banner2", agenda: "Pitching rounds", createdAt: Date())
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
            logo: "quizzardsLogo",
            clubLeadId: leadId,
            facultyId: eventManagementFacultyId,

            vicePresidentId: vpTechId,

//            vicePresidentId: nil,
            instituteId: instituteId,
            status: .active,
            createdAt: Date(),
            memberCount: 30,
            eventCount: 15,
            socials: [
                "instagram": "https://instagram.com/",
                "facebook": "https://facebook.com/",
                "linkedin": "https://linkedin.com/company/",
                "discord": "https://discord.gg/",
                "whatsapp": "https://wa.me/"
            ]
        )
        
        let users = [
            User(id: leadId, email: "qzlead", name: "Aditi", instituteId: instituteId, role: .clubLead, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech IT", year: "4th Year", bio: "Quizzer.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "qzm1", name: "Rahul", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech IT", year: "4th Year", bio: "Quizzer.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "qzm2", name: "Shivam", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech IT", year: "4th Year", bio: "Quizzer.", createdAt: Date(), status: .active),
            User(id: UUID(), email: "qzm3", name: "Harshit", instituteId: instituteId, role: .clubMember, clubId: clubId, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech IT", year: "4th Year", bio: "Quizzer.", createdAt: Date(), status: .active)
        ]
        
        return MockClubBundle(club: club, users: users, events: [], announcements: [])
    }()

    // MARK: - Collections
    static let allBundles = [technoJamBundle, lingoFreaksBundle, eCellBundle, quizzardsBundle]

    static let allClubs: [Club] = allBundles.map { $0.club }

    static let allMockUsers: [User] = {
        var users = allBundles.flatMap { $0.users }
        

        // Add President
        users.append(User(id: presidentId, email: "president", name: "Dr. Arun Mehra", instituteId: instituteId, role: .president, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "Administration", year: "N/A", bio: "University President", createdAt: Date(), status: .active))
        
        // Add Vice Presidents
        users.append(User(id: vpTechId, email: "vpTech", name: "Rahul Sharma", instituteId: instituteId, role: .vicePresident, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "Council", year: "4th Year", bio: "VP Technical", createdAt: Date(), status: .active))
        users.append(User(id: vpLitId, email: "vpLit", name: "Kavya Gupta", instituteId: instituteId, role: .vicePresident, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "Council", year: "4th Year", bio: "VP Literary", createdAt: Date(), status: .active))
        users.append(User(id: vpBizId, email: "vpBiz", name: "Ishaan Verma", instituteId: instituteId, role: .vicePresident, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "Council", year: "4th Year", bio: "VP Professional", createdAt: Date(), status: .active))

        // Add Event Management Team
        users.append(User(id: eventManagementFacultyId, email: "emt", name: "Event Management Team", instituteId: instituteId, role: .faculty, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "Administration", year: "N/A", bio: "Centralized Event Management Team Hub", createdAt: Date(), status: .active))
        
        // Add more members for TechJam
//        users.append(User(id: UUID(), email: "tjm3", name: "Ananya", instituteId: instituteId, role: .clubMember, clubId: technoJamBundle.club.id, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "2nd Year", bio: "AI enthusiast.", createdAt: Date(), status: .active))
//        users.append(User(id: UUID(), email: "tjm4", name: "Rohan", instituteId: instituteId, role: .clubMember, clubId: technoJamBundle.club.id, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech CSE", year: "3rd Year", bio: "Designer", createdAt: Date(), status: .active))
        
        // Add more students
        users.append(User(id: UUID(), email: "s1", name: "Priya", instituteId: instituteId, role: .student, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "B.Sc Physics", year: "1st Year", bio: "user2", createdAt: Date(), status: .active))
        users.append(User(id: UUID(), email: "s2", name: "Amit", instituteId: instituteId, role: .student, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "B.Com", year: "2nd Year", bio: "", createdAt: Date(), status: .active))
        users.append(User(id: UUID(), email: "s3", name: "Sneha", instituteId: instituteId, role: .student, clubId: nil, profileImg: "user2", phoneNumber: "0000000000", course: "B.Tech ME", year: "4th Year", bio: "", createdAt: Date(), status: .active))
        
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
    
    static let placeholderUser = User(id: UUID(), email: "placeholder", name: "User", instituteId: instituteId, role: .student, clubId: nil, profileImg: "user2", phoneNumber: "", course: "", year: "", bio: "", createdAt: Date(), status: .active)

    static let sampleApprovals: [Approval] = {
        let techSummitId = sampleEvents.first { $0.title.contains("Annual Tech Summit") }?.id ?? UUID()
        let musicNightId = sampleEvents.first { $0.title.contains("Euphoria") }?.id ?? UUID()
        let leadId = clubLeadUser.id
        
        return [
            Approval(id: UUID(), type: .event, senderId: leadId, receiverId: facultyResource.id, eventId: techSummitId, approvalRelatedId: techSummitId, status: .pending, remarks: [Remark(id: UUID(), approvalId: UUID(), authorId: leadId, content: "Event creation approval requested", createdAt: Date().addingTimeInterval(-172800))], createdAt: Date().addingTimeInterval(-172800), updatedAt: Date()),
            Approval(id: UUID(), type: .resource, senderId: leadId, receiverId: facultyResource.id, eventId: techSummitId, approvalRelatedId: techSummitId, status: .pending, remarks: [], createdAt: Date().addingTimeInterval(-7200), updatedAt: Date()),
            Approval(id: UUID(), type: .budget, senderId: leadId, receiverId: presidentId, eventId: musicNightId, approvalRelatedId: UUID(), status: .pending, remarks: [], createdAt: Date().addingTimeInterval(-3600), updatedAt: Date()),
            Approval(id: UUID(), type: .venue, senderId: leadId, receiverId: facultyVenue.id, eventId: techSummitId, approvalRelatedId: techSummitId, status: .pending, remarks: [], createdAt: Date().addingTimeInterval(-86400), updatedAt: Date())
        ]
    }()

    static let sampleResources: [Resource] = {
        let techSummitId = sampleEvents.first { $0.title.contains("Annual Tech Summit") }?.id ?? UUID()
        let musicNightId = sampleEvents.first { $0.title.contains("Euphoria") }?.id ?? UUID()
        let startupPitchId = sampleEvents.first { $0.title.contains("Idea Tank") }?.id ?? UUID()
        
        let leadId = clubLeadUser.id
        
        return [
            // Technojam University Resources
            Resource(id: UUID(), eventId: techSummitId, name: "Projectors", quantity: 5, type: .university, status: .pending, addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-172800)),
            Resource(id: UUID(), eventId: techSummitId, name: "Extension Boards", quantity: 10, type: .university, status: .approved, addedBy: leadId, remarks: [Remark(id: UUID(), approvalId: UUID(), authorId: eventManagementFacultyId, content: "Approved for the event", createdAt: Date().addingTimeInterval(-80000))], createdAt: Date().addingTimeInterval(-86400)),
            
            // Lingo Freaks External Rentals
            Resource(id: UUID(), eventId: musicNightId, name: "Concert Stage Lights", quantity: 12, type: .external, status: .pending, cost: 15000, vendorName: "Bright Events", addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-129600)),
            Resource(id: UUID(), eventId: musicNightId, name: "Professional Sound System", quantity: 1, type: .external, status: .pending, cost: 25000, vendorName: "Echo Pro Audio", addedBy: leadId, remarks: [
                Remark(id: UUID(), approvalId: UUID(), authorId: eventManagementFacultyId, content: "Cost seems a bit high. Can we negotiate?", createdAt: Date().addingTimeInterval(-70000)),
                Remark(id: UUID(), approvalId: UUID(), authorId: leadId, content: "Already negotiated, this is the best price.", createdAt: Date().addingTimeInterval(-60000)),
                Remark(id: UUID(), approvalId: UUID(), authorId: eventManagementFacultyId, content: "Okay, please provide the quotation.", createdAt: Date().addingTimeInterval(-50000))
            ], createdAt: Date().addingTimeInterval(-86400)),
            Resource(id: UUID(), eventId: musicNightId, name: "Plastic Chairs", quantity: 200, type: .external, status: .approved, cost: 2000, vendorName: "Local Rentals", addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-43200)),
            
            // Technojam External Rentals
            Resource(id: UUID(), eventId: techSummitId, name: "Premium Catering", quantity: 50, type: .external, status: .pending, cost: 35000, vendorName: "Gourmet Hub", addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-259200)),
            
            // E-Cell University Resources
            Resource(id: UUID(), eventId: startupPitchId, name: "Movable Whiteboards", quantity: 4, type: .university, status: .pending, addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-72000))
        ]
    }()

    static let sampleBudgets: [Budget] = {
        let techSummitId = sampleEvents.first { $0.title.contains("Annual Tech Summit") }?.id ?? UUID()
        let musicNightId = sampleEvents.first { $0.title.contains("Euphoria") }?.id ?? UUID()
        let leadId = clubLeadUser.id
        
        return [
            Budget(id: UUID(), eventId: techSummitId, itemName: "Swags & T-shirts", unitPrice: 500, quantity: 100, status: .pending, addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-86400)),
            Budget(id: UUID(), eventId: techSummitId, itemName: "Food & Refreshments", unitPrice: 200, quantity: 150, status: .pending, addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-86400)),
            Budget(id: UUID(), eventId: musicNightId, itemName: "Artist Fee", unitPrice: 100000, quantity: 1, status: .pending, addedBy: leadId, remarks: [], createdAt: Date().addingTimeInterval(-172800))
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
