import SwiftUI

struct UpcomingEventsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                ForEach(MockData.sampleEvents) { event in
                    NavigationLink(value: event) {
                        ExploreEventCard(event: event, isMyEvent: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event, isMyEvent: true)
        }
    }
}
