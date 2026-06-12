import Foundation
import Observation

@Observable
final class StudentDashboardStore {
    var searchText: String = ""
    var selectedCategory: ClubCategory? = nil
    
    private var clubStore: ClubStore
    private var eventStore: EventStore
    
    var registeredEventIds: Set<UUID> = []
    
    init(clubStore: ClubStore, eventStore: EventStore) {
        self.clubStore = clubStore
        self.eventStore = eventStore
    }
    
    var filteredClubs: [Club] {
        clubStore.allClubs.filter { club in
            let matchesSearch = searchText.isEmpty || 
                                club.name.localizedCaseInsensitiveContains(searchText) || 
                                (club.description ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || club.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var registeredEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return eventStore.events.filter { event in
            registeredEventIds.contains(event.id) &&
            Calendar.current.startOfDay(for: event.startDate) >= today
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func selectCategory(_ category: ClubCategory?) {
        selectedCategory = category
    }
}
