import SwiftUI
import ClubItShared

struct UpcomingEventsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                let today = Calendar.current.startOfDay(for: Date())
                let upcomingEvents = appSession.eventStore.events.filter { event in
                    event.subgroupId == user.subgroupId &&
                    Calendar.current.startOfDay(for: event.startDate) >= today
                }.sorted { $0.startDate < $1.startDate }
                
                if upcomingEvents.isEmpty {
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .glassEffect(in: .rect(cornerRadius: 16))
                } else {
                    ForEach(upcomingEvents) { event in
                        NavigationLink(value: event) {
                            ExploreEventCard(event: event, isMyEvent: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event, isMyEvent: true)
        }
    }
}
