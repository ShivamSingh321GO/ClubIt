import Foundation
import Observation

@Observable
public final class StudentDashboardStore {
    public var searchText: String = ""
    public var selectedCategory: ClubCategory? = nil
    
    private var clubStore: ClubStore
    private var eventStore: EventStore
    
    public var registeredEventIds: Set<UUID> = []
    
    public init(clubStore: ClubStore, eventStore: EventStore) {
        self.clubStore = clubStore
        self.eventStore = eventStore
    }
    
    public var filteredClubs: [Club] {
        clubStore.allClubs.filter { club in
            let matchesSearch = searchText.isEmpty || 
                                club.name.localizedCaseInsensitiveContains(searchText) || 
                                (club.description ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || club.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    public var registeredEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return eventStore.events.filter { event in
            registeredEventIds.contains(event.id) &&
            Calendar.current.startOfDay(for: event.startDate) >= today
        }.sorted { $0.startDate < $1.startDate }
    }
    
    public func selectCategory(_ category: ClubCategory?) {
        selectedCategory = category
    }
}
