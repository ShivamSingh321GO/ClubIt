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
        eventStore.events.filter { registeredEventIds.contains($0.id) }
    }
    
    func selectCategory(_ category: ClubCategory?) {
        selectedCategory = category
    }
}
