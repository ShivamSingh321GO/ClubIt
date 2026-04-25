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
    
    func updateClub(name: String, tagLine: String, description: String, category: ClubCategory, memberCount: Int, eventCount: Int, socials: [String: String], logo: String, imageData: Data?) {
        club.name = name
        club.tagLine = tagLine
        club.description = description
        club.category = category
        club.memberCount = memberCount
        club.eventCount = eventCount
        club.socials = socials
        club.logo = logo
        club.imageData = imageData
    }
    
    func toggleFollow(for clubId: UUID) {
        if followedClubIds.contains(clubId) {
            followedClubIds.remove(clubId)
        } else {
            followedClubIds.insert(clubId)
        }
    }
    
    func updateMember(updatedUser: User) {
        if let index = allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
            allUsers[index] = updatedUser
        }
    }
}
