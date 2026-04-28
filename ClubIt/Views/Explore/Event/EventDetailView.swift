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
                        if event.status != .pending {
                            thinDivider
                                .padding(.vertical, 18)
                            
                            registrationSection
                        }
                        
                        // 7. CTA
                        actionButton
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
                    Image(banner).resizable()
                } else {
                    ZStack {
                        Color.orange.opacity(0.1)
                        Image(systemName: "photo").font(.largeTitle).foregroundColor(.orange.opacity(0.5))
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
                    Text(formattedDateTime)
                        .font(.footnote.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
        Group {
            if let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
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
                .fill(Color.orange.gradient.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(organizerName.prefix(1)))
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Organized by")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
                        .foregroundColor(.orange)
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
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
                Text("About the Event")
                    .font(.headline)
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                Text("Event Agenda")
                    .font(.headline)
                
                let lines = agenda.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    Text("Registrations")
                        .font(.headline)
                    
                    Group {
                        Text("\(event.status == .approved ? 0 : (event.numberOfRegistrations ?? 0)) Registered / ")
                        + Text("\(event.maxParticipants)")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                        + Text(" total")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if event.status != .approved {
                    if appSession.registrationStore.getRegistrations(for: event.id).count >= event.maxParticipants {
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
                            Text("\(event.maxParticipants - appSession.registrationStore.getRegistrations(for: event.id).count) slots left")
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
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Group {
            if event.status == .pending {
                Button(action: {}) {
                    Text("Pending Approval")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                .disabled(true)
            } else if isMyEvent {
                if event.status == .approved {
                    Button {
                        isShowingPublishAlert = true
                    } label: {
                        Text("Publish Event")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                } else {
                    NavigationLink(destination: ManageParticipantsView(event: event)) {
                        Text("View Participants")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.blue)
                }
            } else if appSession.currentRole == .faculty {
                Button(action: {}) {
                    Text("No Registration Required")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(true)
                .padding(.top, 12)
            } else {
                let isRegistered = appSession.registeredEventIds.contains(event.id)
                let isFull = appSession.registrationStore.getRegistrations(for: event.id).count >= event.maxParticipants
                
                Button {
                    if isRegistered {
                        isShowingWithdrawConfirmAlert = true
                    } else if !isFull {
                        if event.registrationType == .team {
                            isShowingRegistrationForm = true
                        } else {
                            isShowingRegisterConfirmAlert = true
                        }
                    }
                } label: {
                    Text(isRegistered ? "Withdraw Registration" : (isFull ? "Event Full" : "Register Now"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(isRegistered ? .red : (isFull ? .secondary : .orange))
                .disabled(!isRegistered && isFull)
            }
        }
    }
    
    
    // MARK: - Utility
    
    private var thinDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 1)
    }
    
    // MARK: - Helpers
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: event.startDate)
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
        appSession.clubStore.allClubs.first { $0.id == event.clubId }?.name ?? "Event Organizer"
    }
    
    private var registrationProgress: Double {
        guard event.maxParticipants > 0 else { return 0 }
        return min(Double(event.numberOfRegistrations ?? 0) / Double(event.maxParticipants), 1.0)
    }
    
    private var buttonColor: Color {
        if isMyEvent { return .blue }
        return appSession.registeredEventIds.contains(event.id) ? .green : .orange
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: MockData.technoJamBundle.events[0], isMyEvent: false)
            .environment(MockData.session(for: .student))
    }
}
