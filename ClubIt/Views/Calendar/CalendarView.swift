//
//  CalendarView.swift
//  ClubIt
//
//  Created by Ansh Srivastava on 3/23/26.
//

import SwiftUI

struct CalendarView: View {
    @Environment(AppSession.self) private var appSession
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .glassEffect(in: .rect(cornerRadius: 20))
            
            
            // Event List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    let eventsForSelectedDate = events(for: selectedDate)
                    
                    if eventsForSelectedDate.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No events for this day")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(eventsForSelectedDate) { event in
                            NavigationLink {
                                EventDetailView(event: event, isMyEvent: isMyEvent(event))
                            } label: {
                                CalendarEventCard(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func events(for date: Date) -> [Event] {
        appSession.eventStore.events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
    }
    
    private func isMyEvent(_ event: Event) -> Bool {
        guard let userId = appSession.currentUser?.id else { return false }
        return event.createdBy == userId
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .environment(AppSession())
    }
}

