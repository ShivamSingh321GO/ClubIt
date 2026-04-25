import Foundation
import Observation

@Observable
final class ClubStore {
    var club: Club
    var allClubs: [Club] = []
    var allUsers: [User] = MockData.allMockUsers
    
    var followedClubIds: Set<UUID> = []
    var requestedClubIds: Set<UUID> = []
    
    init() {
        self.club = MockData.technoJamClub
        self.allClubs = MockData.allClubs
    }
    
    func updateClub(name: String, tagLine: String, description: String, category: ClubCategory, memberCount: Int, eventCount: Int, socials: [String: String]) {
        club.name = name
        club.tagLine = tagLine
        club.description = description
        club.category = category
        club.memberCount = memberCount
        club.eventCount = eventCount
        club.socials = socials
    }
    
    func toggleFollow(for clubId: UUID) {
        if followedClubIds.contains(clubId) {
            followedClubIds.remove(clubId)
        } else {
            followedClubIds.insert(clubId)
        }
    }
}
