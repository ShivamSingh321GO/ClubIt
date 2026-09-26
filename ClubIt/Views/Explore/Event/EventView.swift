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
    @State private var eventToDelete: Event? = nil
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
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
                                    .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
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
                Group {
                    if filteredEvents.isEmpty {
                        ScrollView(.vertical, showsIndicators: false) {
                            ContentUnavailableView(
                                "No Events Found",
                                systemImage: "calendar",
                                description: Text("There are no events in this filter right now.")
                            )
                            .padding(.top, 40)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                        .refreshable {
                            try? await appSession.eventStore.fetchAllEvents()
                        }
                    } else {
                        List {
                            ForEach(filteredEvents) { event in
                                ZStack {
                                    NavigationLink {
                                        EventDetailView(event: event, isMyEvent: isMyEvent(event))
                                    } label: {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    ExploreEventCard(
                                        event: event,
                                        isMyEvent: isMyEvent(event)
                                    )
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if canDeleteEvent(event) {
                                        Button(role: .destructive) {
                                            confirmDelete(event)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .contextMenu {
                                    NavigationLink {
                                        EventDetailView(event: event, isMyEvent: isMyEvent(event))
                                    } label: {
                                        Label("View Details", systemImage: "info.circle")
                                    }
                                    
                                    if canDeleteEvent(event) {
                                        Divider()
                                        Button(role: .destructive) {
                                            confirmDelete(event)
                                        } label: {
                                            Label("Delete Event", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        .refreshable {
                            try? await appSession.eventStore.fetchAllEvents()
                        }
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 70)
                        }
                    }
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
        .alert("Delete Event?", isPresented: $showDeleteConfirmation, presenting: eventToDelete) { event in
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    deleteEvent(event)
                }
            }
            Button("Cancel", role: .cancel) {
                eventToDelete = nil
            }
        } message: { event in
            Text("Are you sure you want to delete \"\(event.title)\"? This action cannot be undone.")
        }
    }
    
    private func canDeleteEvent(_ event: Event) -> Bool {
        if let currentUserId = appSession.currentUser?.id, event.createdBy == currentUserId {
            return true
        }
        
        guard let role = appSession.currentRole else {
            return isMyEvent(event)
        }
        
        switch role {
        case .superAdmin, .admin, .groupLead, .groupSubLead, .subGroupLead:
            return true
        case .subGroupMember, .guest:
            return isMyEvent(event)
        }
    }
    
    private func confirmDelete(_ event: Event) {
        eventToDelete = event
        showDeleteConfirmation = true
    }
    
    private func deleteEvent(_ event: Event) {
        Task {
            isDeleting = true
            do {
                try await eventStore.deleteEvent(event)
            } catch {
                print("❌ [EventView] Error deleting event: \(error)")
            }
            isDeleting = false
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
