import Foundation
import Observation

@Observable
public final class StudentDashboardStore {
    public var searchText: String = ""
    public var selectedCategory: String? = nil
    
    private var subgroupStore: SubgroupStore
    private var eventStore: EventStore
    
    public var registeredEventIds: Set<UUID> = []
    
    public init(subgroupStore: SubgroupStore, eventStore: EventStore) {
        self.subgroupStore = subgroupStore
        self.eventStore = eventStore
    }
    
    /// Dynamic categories extracted directly from all subgroups in the database
    public var availableCategories: [String] {
        var seen = Set<String>()
        var categories: [String] = []
        for subgroup in subgroupStore.allSubgroups {
            let cat = subgroup.category.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cat.isEmpty && !seen.contains(cat.lowercased()) {
                seen.insert(cat.lowercased())
                categories.append(cat)
            }
        }
        return categories.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    public var filteredSubgroups: [Subgroup] {
        subgroupStore.allSubgroups.filter { subgroup in
            let matchesSearch = searchText.isEmpty || 
                                subgroup.name.localizedCaseInsensitiveContains(searchText) || 
                                (subgroup.description ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory: Bool
            if let selected = selectedCategory, !selected.isEmpty {
                matchesCategory = subgroup.category.localizedCaseInsensitiveCompare(selected) == .orderedSame
            } else {
                matchesCategory = true
            }
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
    
    public func selectCategory(_ category: String?) {
        selectedCategory = category
    }
    
    public func selectCategory(_ category: SubgroupCategory?) {
        selectedCategory = category?.rawValue
    }
}
