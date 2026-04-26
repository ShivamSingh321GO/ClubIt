import Foundation
import Observation

@Observable
final class ClubFileStore {
    var files: [ClubFile] = []
    
    init(clubId: UUID? = nil) {
        let mockClubId = clubId ?? UUID()
        // Mock data
        files = [
            ClubFile(id: UUID(), clubId: mockClubId, name: "Event_TechSummit.doc", size: "2.4 MB", uploadedBy: "Atharv Shetty", date: "Nov 28, 2024"),
            ClubFile(id: UUID(), clubId: mockClubId, name: "Budget_Sheet_Q1.xlsx", size: "1.2 MB", uploadedBy: "Shivam Singh", date: "Dec 05, 2024"),
            ClubFile(id: UUID(), clubId: mockClubId, name: "Marketing_Plan.pdf", size: "4.8 MB", uploadedBy: "Kamakshi Gupta", date: "Jan 12, 2025")
        ]
    }
    
    func addFile(_ file: ClubFile) {
        files.insert(file, at: 0)
    }
    
    func deleteFile(_ file: ClubFile) {
        files.removeAll { $0.id == file.id }
    }
}
