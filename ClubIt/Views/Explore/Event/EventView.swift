//
//  EventView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//

import SwiftUI
import ClubItShared

enum EventScope {
    case allEvents
    case followed
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
    @State private var isRefreshing = false
    
    private func triggerRefresh(action: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.15)) {
            isRefreshing = true
        }
        
        // Brief delay to simulate a real refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                action()
                isRefreshing = false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            ZStack(alignment: .trailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventFilterCategory.allCases) { category in
                            let isSelected = selectedCategory == category
                            Button {
                                triggerRefresh {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill).opacity(0.5), in: Capsule())
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, shouldShowToggle ? 85 : 0)
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: shouldShowToggle ? 0.7 : 1.0),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                if shouldShowToggle {
                    VStack(spacing: -3) {
                        Text(appSession.currentRole == .subGroupLead || appSession.currentRole == .subGroupMember ? "MY\nEVENTS" : (appSession.currentRole == .groupLead ? "GROUP\nEVENTS" : (appSession.currentRole == .groupSubLead ? "MY SUBGROUP\nEVENTS" : "SUBGROUP\nFOLLOWED")))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 9, weight: .black))
                            .lineLimit(2)
                            .foregroundStyle(scope == .followed ? .accentColor : .secondary)
                        
                        Toggle("", isOn: Binding(
                            get: { scope == .followed },
                            set: { newValue in
                                triggerRefresh {
                                    scope = newValue ? .followed : .allEvents
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .labelsHidden()
                        .scaleEffect(0.72)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color(.systemBackground).opacity(0.6), location: 0.4),
                                .init(color: Color(.systemBackground).opacity(0.9), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .blur(radius: 8)
                    )
                    .padding(.trailing, 4)
                }
            }
            
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if filteredEvents.isEmpty {
                            ContentUnavailableView(
                                "No Events Found",
                                systemImage: "calendar",
                                description: Text("There are no events in this filter right now.")
                            )
                            .padding(.top, 40)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
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
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
                .refreshable {
                    try? await appSession.eventStore.fetchAllEvents()
                }
                .opacity(isRefreshing ? 0 : 1)
                
                if isRefreshing {
                    VStack {
                        ProgressView()
                            .tint(.accentColor)
                            .scaleEffect(1.2)
                        Text("Refreshing events...")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }
    
    private var shouldShowToggle: Bool {
        appSession.currentRole != .groupSubLead
    }
    
    private var filteredEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        
        return eventStore.events.filter { event in
            if Calendar.current.startOfDay(for: event.startDate) < today {
                return false
            }
            
            let matchesScope: Bool
            
            switch scope {
            case .allEvents:
                matchesScope = true
            case .followed:
                if appSession.currentRole == .subGroupLead || appSession.currentRole == .subGroupMember {
                    matchesScope = event.subgroupId == appSession.currentUser?.subgroupId
                } else if appSession.currentRole == .groupLead {
                    matchesScope = event.subgroupId == nil
                } else if appSession.currentRole == .groupSubLead {
                    let assignedSubgroupIds = Set(appSession.subgroupStore.allSubgroups.filter { $0.vicePresidentId == appSession.currentUser?.id }.map { $0.id })
                    if let subgroupId = event.subgroupId {
                        matchesScope = assignedSubgroupIds.contains(subgroupId)
                    } else if let subgroupIds = event.subgroupIds {
                        matchesScope = !assignedSubgroupIds.intersection(subgroupIds).isEmpty
                    } else {
                        matchesScope = false
                    }
                } else {
                    if let subgroupId = event.subgroupId {
                        matchesScope = appSession.subgroupStore.followedSubgroupIds.contains(subgroupId)
                    } else if let subgroupIds = event.subgroupIds {
                        matchesScope = !appSession.subgroupStore.followedSubgroupIds.intersection(subgroupIds).isEmpty
                    } else {
                        matchesScope = false
                    }
                }
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
            
            let matchesStatus: Bool = {
                if isMyEvent(event) { return true }
                return event.status == .published
            }()
            
            return matchesScope && matchesCategory && matchesStatus
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func isMyEvent(_ event: Event) -> Bool {
        guard let userId = appSession.currentUser?.id else { return false }
        return event.createdBy == userId
    }
}

#Preview {
    NavigationStack {
        EventView(scope: .constant(.allEvents), eventStore: EventStore())
            .environment(MockData.session(for: .subGroupLead))
    }
}
