import Foundation
import Observation

@Observable
final class AchievementStore {
    var achievements: [Achievement] = []
    
    init(clubId: UUID? = nil) {
        let mockClubId = clubId ?? UUID()
        achievements = [
            Achievement(id: UUID(), clubId: mockClubId,
                title: "Best Tech Club 2024",
                description: "Awarded for outstanding contribution to technology education and innovation",
                type: .award,
                createdAt: Date()
            ),
            Achievement(id: UUID(), clubId: mockClubId,
                title: "Industry Collaboration Initiated",
                description: "Successfully organized the club's first technical workshop with strong student participation.",
                type: .milestone,
                createdAt: Date()
            ),
            Achievement(id: UUID(), clubId: mockClubId,
                title: "Certificate of Appreciation",
                description: "Received a certificate for active participation in inter-college technical events.",
                type: .recognition,
                createdAt: Date()
            )
        ]
    }
    
    func addAchievement(_ achievement: Achievement) {
        achievements.append(achievement)
    }
    
    func deleteAchievement(_ achievement: Achievement) {
        achievements.removeAll { $0.id == achievement.id }
    }
}
