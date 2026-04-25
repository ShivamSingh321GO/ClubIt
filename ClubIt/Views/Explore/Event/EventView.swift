//
//  EventView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//

import SwiftUI

enum EventScope {
    case allEvents
    case myEvents
}

enum EventFilterCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case tech = "Tech"
    case ai = "AI"
    case cultural = "Cultural"
    case workshop = "Workshop"
    case wellness = "Wellness"
    case sports = "Sports"
    
    var id: String { rawValue }
}

struct EventView: View {
    
    @Environment(AppSession.self) private var appSession
    @Binding var scope: EventScope
    
    let eventStore: EventStore
    
    @State private var selectedCategory: EventFilterCategory = .all
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            HStack(alignment: .center, spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventFilterCategory.allCases) { category in
                            let isSelected = selectedCategory == category
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category.rawValue)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 65)
                                    .background(isSelected ? Color(.secondarySystemFill) : Color(.tertiarySystemFill).opacity(0.5), in: Capsule())
                                    .foregroundStyle(.primary)
                                    .glassEffect(in: .capsule)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(spacing: -2) {
                    Text("MY EVENT ")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(scope == .myEvents ? .orange : .secondary)
                    
                    Toggle("", isOn: Binding(
                        get: { scope == .myEvents },
                        set: { scope = $0 ? .myEvents : .allEvents }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    .labelsHidden()
                    .scaleEffect(0.75)
                }
                .padding(.leading, 4)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if filteredEvents.isEmpty {
                        ContentUnavailableView(
                            "No Events Found",
                            systemImage: "calendar",
                            description: Text("There are no events in this filter right now.")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredEvents) { event in
                            NavigationLink {
                                EventDetailView(event: event, isMyEvent: isMyEvent(event))
                            } label: {
                                ExploreEventCard(
                                    event: event,
                                    isMyEvent: isMyEvent(event)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
    
    private var filteredEvents: [Event] {
        eventStore.events.filter { event in
            let matchesScope: Bool
            
            switch scope {
            case .allEvents:
                matchesScope = true
            case .myEvents:
                matchesScope = isMyEvent(event)
            }
            
            let matchesCategory: Bool
            switch selectedCategory {
            case .all:
                matchesCategory = true
            case .tech:
                matchesCategory = event.category == .technical
            case .ai:
                matchesCategory = event.category == .ai
            case .cultural:
                matchesCategory = event.category == .entertainment
            case .workshop:
                matchesCategory = event.category == .workshop
            case .wellness:
                matchesCategory = event.category == .wellness
            case .sports:
                matchesCategory = event.category == .sports
            }
            
            return matchesScope && matchesCategory
        }
    }
    
    private func isMyEvent(_ event: Event) -> Bool {
        guard let userId = appSession.currentUser?.id else { return false }
        return event.createdBy == userId
    }
}

#Preview {
    NavigationStack {
        EventView(scope: .constant(.allEvents), eventStore: EventStore())
            .environment(MockData.session(for: .clubLead))
    }
}
