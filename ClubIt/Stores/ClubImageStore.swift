import Foundation
import Observation

struct ClubImageSection: Identifiable {
    var id = UUID()
    var title: String
    var images: [ClubImage]
    var remainingCount: Int
}

@Observable
final class ClubImageStore {
    var sections: [ClubImageSection] = []
    
    init(clubId: UUID? = nil) {
        let mockClubId = clubId ?? UUID()
        let euphoricImages = (1...13).map { index in
            ClubImage(
                clubId: mockClubId,
                eventId: UUID(),
                type: .image,
                title: "Euphoria Fest Image \(index)",
                fileUrl: "image1",
                uploadedBy: UUID(),
                createdAt: Date()
            )
        }
        
        let carnivalImages = (1...10).map { index in
            ClubImage(
                clubId: mockClubId,
                eventId: UUID(),
                type: .image,
                title: "Campus Carnival Image \(index)",
                fileUrl: "image2",
                uploadedBy: UUID(),
                createdAt: Date()
            )
        }
        
        sections = [
            ClubImageSection(title: "Euphoria Fest", images: euphoricImages, remainingCount: euphoricImages.count - 6),
            ClubImageSection(title: "Campus Carnival", images: carnivalImages, remainingCount: carnivalImages.count - 6),
            ClubImageSection(title: "Club Meetup", images: euphoricImages.prefix(5).map { $0 }, remainingCount: 0)
        ]
    }
    
    func addSection(_ section: ClubImageSection) {
        sections.insert(section, at: 0)
    }
    
    func addImageToSection(sectionId: UUID, image: ClubImage) {
        if let index = sections.firstIndex(where: { $0.id == sectionId }) {
            sections[index].images.insert(image, at: 0)
            sections[index].remainingCount = max(0, sections[index].images.count - 6)
        }
    }
}
