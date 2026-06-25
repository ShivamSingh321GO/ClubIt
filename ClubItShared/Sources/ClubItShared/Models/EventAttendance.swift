import Foundation

public struct EventAttendance: Identifiable, Codable, Hashable {
    public var id: UUID
    public var eventId: UUID
    public var userId: UUID
    public var entryTime: Date?
    public var exitTime: Date?
    public var createdAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case entryTime = "entry_time"
        case exitTime = "exit_time"
        case createdAt = "created_at"
    }

    public init(id: UUID = UUID(), eventId: UUID, userId: UUID, entryTime: Date? = nil, exitTime: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.entryTime = entryTime
        self.exitTime = exitTime
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        eventId = try container.decode(UUID.self, forKey: .eventId)
        userId = try container.decode(UUID.self, forKey: .userId)
        
        // Custom date parsing to handle potentially varying formats from Supabase
        let dateStringDecoder = { (key: CodingKeys) -> Date? in
            guard let str = try? container.decode(String.self, forKey: key) else { return nil }
            return EventAttendance.parseDate(str)
        }
        
        entryTime = dateStringDecoder(.entryTime)
        exitTime = dateStringDecoder(.exitTime)
        createdAt = dateStringDecoder(.createdAt) ?? Date()
    }
    
    static func parseDate(_ string: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) { return date }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: string) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
