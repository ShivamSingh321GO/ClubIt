import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let eventId: UUID
    let isMyEvent: Bool
    
    private let initialEvent: Event
    
    var event: Event {
        appSession.eventStore.events.first(where: { $0.id == eventId }) ?? initialEvent
    }
    
    init(event: Event, isMyEvent: Bool) {
        self.initialEvent = event
        self.eventId = event.id
        self.isMyEvent = isMyEvent
    }
    
    @State private var isShowingRegistrationForm = false
    @State private var isShowingPublishAlert = false
    @State private var isShowingRegisterConfirmAlert = false
    @State private var isShowingWithdrawConfirmAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // 1. Hero Banner
                    headerSection
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: 0) {
                        // 2. Quick Details
                        quickDetailsRow
                            .padding(.top, 22)
                        
                        thinDivider
                            .padding(.vertical, 18)
                        
                        // 3. Organizer
                        organizerRow
                        
                        thinDivider
                            .padding(.vertical, 18)
                        
                        // 4. About
                        aboutSection
                        
                        // 5. Agenda
                        if let agenda = event.agenda, !agenda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            thinDivider
                                .padding(.vertical, 20)
                            
                            agendaSection(agenda)
                        }
                        
                        // 6. Registration Progress
                        if event.status != .pending && (event.isRegistrationOpen ?? true) {
                            thinDivider
                                .padding(.vertical, 18)
                            
                            registrationSection
                        }
                        
                        // 7. CTA
                        nativePremiumButton
                            .padding(.top, 24)
                            .padding(.bottom, 30)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ready to Go Live?", isPresented: $isShowingPublishAlert) {
            Button("Publish Now", role: .none) {
                Task {
                    do {
                        try await appSession.eventStore.updateEventStatus(id: event.id, status: .published)
                        print("DEBUG: Event \(event.id) published successfully")
                    } catch {
                        print("ERROR: Failed to publish event: \(error)")
                    }
                }
            }
            Button("Not Yet", role: .cancel) {}
        } message: {
            Text("Publishing will make this event visible to everyone and open up registrations. Are you sure you want to proceed?")
        }
        .alert("Confirm Registration", isPresented: $isShowingRegisterConfirmAlert) {
            Button("Register", role: .none) {
                Task {
                    await appSession.registerForEvent(id: event.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to register for this event?")
        }
        .alert("Withdraw Registration", isPresented: $isShowingWithdrawConfirmAlert) {
            Button("Withdraw", role: .destructive) {
                Task {
                    await appSession.registerForEvent(id: event.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to withdraw your registration? This will free up your slot.")
        }
        .sheet(isPresented: $isShowingRegistrationForm) {
            DynamicRegistrationFormView(event: event)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage).resizable()
                } else if let banner = event.bannerImage, !banner.isEmpty {
                    if banner.hasPrefix("http") {
                        AsyncImage(url: URL(string: banner)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                            case .failure:
                                ZStack {
                                    Color.accentColor.opacity(0.1)
                                    Image(systemName: "photo").font(.largeTitle).foregroundColor(.accentColor.opacity(0.5))
                                }
                            case .empty:
                                ZStack {
                                    Color.accentColor.opacity(0.05)
                                    ProgressView()
                                }
                            @unknown default:
                                ZStack {
                                    Color.accentColor.opacity(0.1)
                                    Image(systemName: "photo").font(.largeTitle).foregroundColor(.accentColor.opacity(0.5))
                                }
                            }
                        }
                    } else {
                        Image(banner).resizable()
                    }
                } else {
                    ZStack {
                        Color.accentColor.opacity(0.1)
                        Image(systemName: "photo").font(.largeTitle).foregroundColor(.accentColor.opacity(0.5))
                    }
                }
            }
            .aspectRatio(16/10, contentMode: .fill)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            VStack {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(event.category.displayName)
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 4)
                }
                .padding(20)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(event.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    // MARK: - Quick Details (Inline Row)
    
    private var quickDetailsRow: some View {
        HStack(spacing: 0) {
            // Date & Time
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.blue)
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Date & Time")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.dashboardDateLine1)
                            .font(.footnote.bold())
                        Text(event.dashboardDateLine2)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Vertical Divider
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1, height: 34)
                .padding(.horizontal, 12)
            
            // Location
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.red)
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Venue")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(event.location)
                        .font(.footnote.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Organizer (Inline Row)
    
    private var organizerRow: some View {
        let matchingClub = appSession.clubStore.allClubs.first { club in
            if let clubIds = event.clubIds {
                return clubIds.contains(club.id)
            }
            return club.id == event.clubId
        }
        
        return Group {
            if let club = matchingClub {
                NavigationLink(destination: ClubDetailView(club: club)) {
                    organizerContent
                }
            } else {
                organizerContent
            }
        }
        .buttonStyle(.plain)
    }
    
    private var organizerContent: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.gradient.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(organizerName.prefix(1)))
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.clubId == nil ? "Associated Clubs" : "Hosted by")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(organizerName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 10)
            
            if !isMyEvent {
                Button(action: {}) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }    
    // MARK: - About
    
    private var aboutSection: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.teal)
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ABOUT THE EVENT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    
    private func agendaSection(_ agenda: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "list.bullet.indent")
                    .foregroundColor(.purple)
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("EVENT AGENDA")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                let lines = agenda.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Registration (Inline)
    
    private var registrationSection: some View {
        let registrations = appSession.registrationStore.getRegistrations(for: event.id)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.indigo.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.indigo)
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("REGISTRATIONS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Group {
                        if event.maxParticipants >= 999999 {
                            Text("\(registrations.count) Registered")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.primary)
                        } else {
                            Text("\(registrations.count) Registered / ")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.primary)
                            + Text("\(event.maxParticipants) total")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
                
                if event.status != .approved {
                    if !(event.isRegistrationOpen ?? true) {
                        Text("Closed")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    } else if event.maxParticipants > 0 && event.maxParticipants < 999999 && appSession.registrationStore.getRegistrations(for: event.id).count >= event.maxParticipants {
                        Text("Sold Out")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 4, height: 4)
                            Text(event.maxParticipants >= 999999 ? "Unlimited slots" : "\(event.maxParticipants - appSession.registrationStore.getRegistrations(for: event.id).count) slots left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.blue.opacity(0.2), lineWidth: 0.5))
                    }
                }
            }
            if event.status == .approved {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Registration will open after event is published")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.leading, 52)
            }
        }
    }
    
    // MARK: - Native Premium Action Button
    
    private var nativePremiumButton: some View {
        Group {
            if event.status == .pending {
                if let role = appSession.currentUser?.role, role != .vicePresident && role != .president && role != .faculty {
                    Button(action: {}) {
                        Label("Pending Approval", systemImage: "clock.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.secondary)
                    .disabled(true)
                }
            } else if isMyEvent {
                if event.status == .approved {
                    Button {
                        isShowingPublishAlert = true
                    } label: {
                        Label("Publish Event", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.accentColor)
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    if event.isRegistrationOpen ?? true {
                        NavigationLink(destination: ManageParticipantsView(event: event)) {
                            Label("View Participants", systemImage: "person.2.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .tint(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            } else if appSession.currentRole == .faculty || appSession.currentRole == .admin || appSession.currentRole == .president || appSession.currentRole == .vicePresident {
                EmptyView()
            } else {
                let isRegistered = appSession.registeredEventIds.contains(event.id)
                let isFull = event.maxParticipants > 0 && event.maxParticipants < 999999 && appSession.registrationStore.getRegistrations(for: event.id).count >= event.maxParticipants
                let isOpen = event.isRegistrationOpen ?? true
                
                if isRegistered {
                    Button {
                        isShowingWithdrawConfirmAlert = true
                    } label: {
                        Text("Withdraw Registration")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.red)
                } else if !isOpen {
                    Button(action: {}) {
                        Label("Registration Closed", systemImage: "lock.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.secondary)
                    .disabled(true)
                } else if isFull {
                    Button(action: {}) {
                        Label("Event Full", systemImage: "person.crop.circle.badge.xmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.secondary)
                    .disabled(true)
                } else {
                    Button {
                        if event.registrationType == .team {
                            isShowingRegistrationForm = true
                        } else {
                            isShowingRegisterConfirmAlert = true
                        }
                    } label: {
                        Text("Register Now")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.accentColor)
                    .shadow(color: .accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    
    // MARK: - Utility
    
    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title.uppercased(), systemImage: icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
    }
    
    private var thinDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 1)
    }
    
    // MARK: - Helpers
    
    private var formattedDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let startDateStr = dateFormatter.string(from: event.startDate)
        let endDateStr = dateFormatter.string(from: event.endDate)
        
        let startTimeStr = timeFormatter.string(from: event.startTime ?? event.startDate)
        let endTimeStr = event.endTime != nil ? timeFormatter.string(from: event.endTime!) : timeFormatter.string(from: event.endDate)
        
        if startDateStr == endDateStr {
            return "\(startDateStr) • \(startTimeStr) - \(endTimeStr)"
        } else {
            return "\(startDateStr) (\(startTimeStr)) - \(endDateStr) (\(endTimeStr))"
        }
    }
    
    private var categoryIcon: String {
        switch event.category {
        case .workshop: return "wrench.and.screwdriver.fill"
        case .technical: return "desktopcomputer"
        case .entertainment: return "theatermasks.fill"
        case .sports: return "sportscourt.fill"
        case .ai: return "brain.head.profile.fill"
        case .wellness: return "heart.fill"
        case .literary: return "book.fill"
        case .entrepreneurship: return "lightbulb.fill"
        }
    }
    
    private var organizerName: String {
        if let clubIds = event.clubIds, !clubIds.isEmpty {
            let names = clubIds.compactMap { id in appSession.clubStore.allClubs.first(where: { $0.id == id })?.name }
            return names.joined(separator: ", ")
        }
        if let clubId = event.clubId {
            return appSession.clubStore.allClubs.first { $0.id == clubId }?.name ?? "Event Organizer"
        }
        return "Council Event"
    }
    
    private var registrationProgress: Double {
        guard event.maxParticipants > 0 && event.maxParticipants < 999999 else { return 0 }
        return min(Double(event.numberOfRegistrations ?? 0) / Double(event.maxParticipants), 1.0)
    }
    
    private var buttonColor: Color {
        if isMyEvent { return .blue }
        return appSession.registeredEventIds.contains(event.id) ? .green : .accentColor
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: MockData.technoJamBundle.events[0], isMyEvent: false)
            .environment(MockData.session(for: .student))
    }
}
