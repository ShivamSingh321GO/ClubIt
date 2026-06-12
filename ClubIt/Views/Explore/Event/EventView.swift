//
//  EventView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//

import SwiftUI

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
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 65)
                                    .background(isSelected ? Color.orange : Color(.tertiarySystemFill).opacity(0.5), in: Capsule())
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
                        Text(appSession.currentRole == .clubLead || appSession.currentRole == .clubMember ? "MY\nEVENTS" : (appSession.currentRole == .president ? "COUNCIL\nEVENTS" : (appSession.currentRole == .vicePresident ? "MY CLUB\nEVENTS" : "CLUB\nFOLLOWED")))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 9, weight: .black))
                            .lineLimit(2)
                            .foregroundStyle(scope == .followed ? .orange : .secondary)
                        
                        Toggle("", isOn: Binding(
                            get: { scope == .followed },
                            set: { newValue in
                                triggerRefresh {
                                    scope = newValue ? .followed : .allEvents
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
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
                .opacity(isRefreshing ? 0 : 1)
                
                if isRefreshing {
                    VStack {
                        ProgressView()
                            .tint(.orange)
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
        appSession.currentRole != .faculty
    }
    
    private var filteredEvents: [Event] {
        eventStore.events.filter { event in
            let matchesScope: Bool
            
            switch scope {
            case .allEvents:
                matchesScope = true
            case .followed:
                if appSession.currentRole == .clubLead || appSession.currentRole == .clubMember {
                    matchesScope = event.clubId == appSession.currentUser?.clubId
                } else if appSession.currentRole == .president {
                    matchesScope = event.clubId == nil
                } else if appSession.currentRole == .vicePresident {
                    let assignedClubIds = Set(appSession.clubStore.allClubs.filter { $0.vicePresidentId == appSession.currentUser?.id }.map { $0.id })
                    if let clubId = event.clubId {
                        matchesScope = assignedClubIds.contains(clubId)
                    } else if let clubIds = event.clubIds {
                        matchesScope = !assignedClubIds.intersection(clubIds).isEmpty
                    } else {
                        matchesScope = false
                    }
                } else {
                    if let clubId = event.clubId {
                        matchesScope = appSession.clubStore.followedClubIds.contains(clubId)
                    } else if let clubIds = event.clubIds {
                        matchesScope = !appSession.clubStore.followedClubIds.intersection(clubIds).isEmpty
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
