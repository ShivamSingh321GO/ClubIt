import SwiftUI
import ClubItShared

struct HomeVenuesModule: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        let allVenues = appSession.venueStore.allVenues
        let bookedVenues = allVenues.filter { venue in
            let bookedSlots = appSession.venueStore.getBookingInfo(
                for: venue,
                events: appSession.eventStore.events,
                clubs: appSession.clubStore.allClubs
            )
            return !bookedSlots.isEmpty
        }
        
        let venuesToShow = !bookedVenues.isEmpty ? bookedVenues : allVenues
        
        VStack(alignment: .leading, spacing: 16) {
            if venuesToShow.isEmpty {
                Text("No venues found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(venuesToShow.prefix(2)) { venue in
                        VenueRowPreview(venue: venue)
                    }
                }
            }
        }
    }
}

struct VenueRowPreview: View {
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
