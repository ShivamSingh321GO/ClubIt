import SwiftUI

struct ClubItCalendarView: View {
    @Environment(AppSession.self) var appSession
    var standalone: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysInWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        let content = VStack(alignment: .leading, spacing: 20) {
            if !standalone {
                Text("Calendar")
                    .font(.title2)
                    .bold()
            }
            
            VStack(spacing: 16) {
                // Month Header
                HStack {
                    Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button {
                            withAnimation {
                                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.bold())
                                .foregroundColor(.orange)
                        }
                        
                        Button {
                            withAnimation {
                                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.body.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Weekday Header
                HStack(spacing: 0) {
                    ForEach(daysInWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2.bold())
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                
                // Days Grid
                let days = extractDays()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(days) { value in
                        DayCell(value: value, isSelected: calendar.isDate(value.date, inSameDayAs: selectedDate)) { date in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                        .environment(appSession)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 20)
            .glassEffect(in: .rect(cornerRadius: 20))
            
            // Events List
            VStack(alignment: .leading, spacing: 16) {
                let dayEvents = events(for: selectedDate)
                
                if dayEvents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No events scheduled for this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .glassEffect(in: .rect(cornerRadius: 20))
                } else {
                    ForEach(dayEvents) { event in
                        NavigationLink(destination: EventDetailView(event: event, isMyEvent: false)) {
                            CalendarEventMiniCard(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(standalone ? .inline : .automatic)
        .padding(.horizontal, standalone ? 16 : 0)
        
        if standalone {
            ScrollView(showsIndicators: false) {
                content
                    .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
        } else {
            content
        }
    }
    
    private func events(for date: Date) -> [Event] {
        appSession.eventStore.events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    private func extractDays() -> [DateValue] {
        let currentMonthDays = currentMonth.getAllDates()
        
        let firstWeekday = calendar.component(.weekday, from: currentMonthDays.first ?? Date())
        
        var days = currentMonthDays.map { DateValue(day: calendar.component(.day, from: $0), date: $0) }
        
        // Offset for empty days before first day of month
        for _ in 0..<(firstWeekday - 1) {
            days.insert(DateValue(day: -1, date: Date()), at: 0)
        }
        
        return days
    }
}

struct DateValue: Identifiable {
    var id = UUID().uuidString
    var day: Int
    var date: Date
}

struct DayCell: View {
    @Environment(AppSession.self) var appSession
    let value: DateValue
    let isSelected: Bool
    let onSelect: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            if value.day != -1 {
                let hasEvents = appSession.eventStore.events.contains { Calendar.current.isDate($0.startDate, inSameDayAs: value.date) }
                let isToday = Calendar.current.isDateInToday(value.date)
                
                Text("\(value.day)")
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : (isToday ? .orange : .primary))
                    .frame(width: 36, height: 36)
                    .background(
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Color.orange)
                                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                            } else if isToday {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 1.5)
                            }
                        }
                    )
                
                // Event dot
                Circle()
                    .fill(hasEvents ? Color.orange : Color.clear)
                    .frame(width: 4, height: 4)
            } else {
                Text("")
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .onTapGesture {
            if value.day != -1 {
                onSelect(value.date)
            }
        }
    }
}

struct CalendarEventMiniCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                
                Text(event.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                    Text(event.location)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .contentShape(.rect)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

extension Date {
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self)!
        
        var dates: [Date] = []
        let components = calendar.dateComponents([.year, .month], from: self)
        
        for day in range {
            var dateComponents = components
            dateComponents.day = day
            if let date = calendar.date(from: dateComponents) {
                dates.append(date)
            }
        }
        
        return dates
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ClubItCalendarView()
                .environment(MockData.session(for: .clubLead))
        }
    }
}
