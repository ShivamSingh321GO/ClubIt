import Foundation
import Observation

@Observable
final class ClubLinkStore {
    var links: [ClubLink] = []
    
    init(clubId: UUID? = nil) {
        let mockClubId = clubId ?? UUID()
        // Mock data
        links = [
            ClubLink(clubId: mockClubId, name: "Event_TechSummit", url: "https://drive.google.com/drive/folders/1DemoFolderID", uploadedBy: "Atharv Shetty", date: "Nov 28, 2024"),
            ClubLink(clubId: mockClubId, name: "Registration_Form", url: "https://forms.gle/xyz789", uploadedBy: "Shivam Singh", date: "Dec 10, 2024"),
            ClubLink(clubId: mockClubId, name: "Design_Assets", url: "https://figma.com/file/etc", uploadedBy: "Kamakshi Gupta", date: "Jan 05, 2025")
        ]
    }
    
    func addLink(_ link: ClubLink) {
        links.insert(link, at: 0)
    }
    
    func deleteLink(_ link: ClubLink) {
        links.removeAll { $0.id == link.id }
    }
}
