import Foundation
import Observation

@Observable
public final class StudentDashboardStore {
    public var searchText: String = ""
    public var selectedCategory: SubgroupCategory? = nil
    
    private var subgroupStore: SubgroupStore
    private var eventStore: EventStore
    
    public var registeredEventIds: Set<UUID> = []
    
    public init(subgroupStore: SubgroupStore, eventStore: EventStore) {
        self.subgroupStore = subgroupStore
        self.eventStore = eventStore
    }
    
    public var filteredSubgroups: [Subgroup] {
        subgroupStore.allSubgroups.filter { subgroup in
            let matchesSearch = searchText.isEmpty || 
                                subgroup.name.localizedCaseInsensitiveContains(searchText) || 
                                (subgroup.description ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || subgroup.category == selectedCategory
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
    
    public func selectCategory(_ category: SubgroupCategory?) {
        selectedCategory = category
    }
}
