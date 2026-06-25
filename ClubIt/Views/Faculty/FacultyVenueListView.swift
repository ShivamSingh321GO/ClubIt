import SwiftUI
import ClubItShared

struct FacultyVenueListView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: VenueFilter = .all
    @State private var searchText = ""
    @State private var isSearchActive = false
    
    enum VenueFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case auditorium = "Auditorium"
        case aBlock = "A Block"
        case bBlock = "B Block"
        case cBlock = "C Block"
        case library = "Library"
        case grounds = "Grounds"
        case cafeteria = "Cafeteria"
        case labs = "Labs"
        
        var id: String { self.rawValue }
    }
    
    var filteredVenues: [Venue] {
        let venues: [Venue]
        switch selectedFilter {
        case .all: venues = appSession.venueStore.allVenues
        case .auditorium: venues = appSession.venueStore.allVenues.filter { $0.type == .auditorium }
        case .aBlock: venues = appSession.venueStore.allVenues.filter { $0.location.contains("Block A") }
        case .bBlock: venues = appSession.venueStore.allVenues.filter { $0.location.contains("Block B") }
        case .cBlock: venues = appSession.venueStore.allVenues.filter { $0.location.contains("Block C") }
        case .library: venues = appSession.venueStore.allVenues.filter { $0.type == .library }
        case .grounds: venues = appSession.venueStore.allVenues.filter { $0.type == .ground }
        case .cafeteria: venues = appSession.venueStore.allVenues.filter { $0.type == .cafeteria }
        case .labs: venues = appSession.venueStore.allVenues.filter { $0.type == .lab }
        }
        
        if searchText.isEmpty {
            return venues
        } else {
            return venues.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.location.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VenueFilter.allCases) { filter in
                        VenueFilterPill(title: filter.rawValue, isSelected: selectedFilter == filter) {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if filteredVenues.isEmpty {
                        ContentUnavailableView(
                            "No Venues Found",
                            systemImage: "building.2",
                            description: Text(searchText.isEmpty ? "No venues match the selected filter." : "No venues match '\(searchText)'.")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredVenues) { venue in
                            VenueRow(venue: venue)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Venues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, isPresented: $isSearchActive, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Venue")
    }
}

struct VenueFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.white.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .glassEffect(in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

struct VenueRow: View {
    @Environment(AppSession.self) var appSession
    let venue: Venue
    
    var body: some View {
        let bookedSlots = appSession.venueStore.getBookingInfo(
            for: venue,
            events: appSession.eventStore.events,
            clubs: appSession.clubStore.allClubs
        )
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Icon based on type
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(venueColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: venueIcon)
                        .font(.title3)
                        .foregroundColor(venueColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name)
                        .font(.headline)
                        .bold()
                    
                    Text(venue.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                StatusBadge(status: bookedSlots.isEmpty ? .available : .booked)
            }
            
            if !bookedSlots.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("All booked slots")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(0..<bookedSlots.count, id: \.self) { index in
                        let slot = bookedSlots[index]
                        
                        if index > 0 {
                            Divider()
                                .padding(.vertical, 4)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(slot.event.startDate, format: .dateTime.month().day().year())
                                    .font(.subheadline)
                                    .bold()
                                
                                Text("\(slot.event.startTime ?? slot.event.startDate, format: .dateTime.hour().minute()) - \(slot.event.endTime ?? slot.event.endDate, format: .dateTime.hour().minute())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let club = slot.club {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Booked by")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(club.name)
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(venueColor)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private var venueIcon: String {
        switch venue.type {
        case .classroom: return "book.closed.fill"
        case .auditorium: return "theatermasks.fill"
        case .library: return "books.vertical.fill"
        case .ground: return "figure.run"
        case .lab: return "flask.fill"
        case .cafeteria: return "cup.and.saucer.fill"
        }
    }
    
    private var venueColor: Color {
        switch venue.type {
        case .classroom: return .blue
        case .auditorium: return .purple
        case .library: return .green
        case .ground: return .accentColor
        case .lab: return .cyan
        case .cafeteria: return .red
        }
    }
}

struct StatusBadge: View {
    enum Status {
        case available, booked
    }
    let status: Status
    
    var body: some View {
        Text(status == .available ? "Available" : "Booked")
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status == .available ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            )
            .foregroundColor(status == .available ? .green : .red)
    }
}

#Preview {
    NavigationStack {
        FacultyVenueListView()
            .environment(MockData.session(for: .groupSubLead))
    }
}
