import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let event: Event
    let isMyEvent: Bool
    
    @State private var isShowingRegistrationForm = false
    
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
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(event.category.rawValue)
                        .font(.caption.bold())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 4)
                
                Text(event.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
            )
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
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(.orange)
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
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title3)
                        .foregroundColor(.orange)
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
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
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
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "list.bullet.indent")
                    .foregroundColor(.orange)
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
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registrations")
                        .font(.headline)
                    
                    Text("\(event.numberOfRegistrations) joined / \(event.maxParticipants) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if event.numberOfRegistrations >= event.maxParticipants {
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
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("\(event.maxParticipants - event.numberOfRegistrations) left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Avatar Stack (Face Pile)
            HStack(spacing: -12) {
                // Show up to 5 avatars
                let previewRegistrations = registrations.prefix(5)
                ForEach(Array(previewRegistrations.enumerated()), id: \.element.id) { index, reg in
                    if let user = appSession.clubStore.allUsers.first(where: { $0.id == reg.userId }) {
                        Circle()
                            .fill(Color.orange.gradient.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(user.name.prefix(1)))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                            .zIndex(Double(5 - index))
                    }
                }
                
                if registrations.count > 5 {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("+\(registrations.count - 5)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .zIndex(0)
                }
                
                if event.numberOfRegistrations == 0 {
                    Text("Be the first one to join!")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                }
            }
            .padding(.leading, 52)
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
                NavigationLink(destination: ManageParticipantsView(event: event)) {
                    Text("Manage Participants")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.blue)
            } else {
                Button {
                    guard !appSession.registeredEventIds.contains(event.id) else { return }
                    
                    if let form = event.registrationForm, !form.isEmpty {
                        isShowingRegistrationForm = true
                    } else {
                        appSession.registerForEvent(id: event.id)
                    }
                } label: {
                    Text(appSession.registeredEventIds.contains(event.id) ? "Successfully Enrolled" : "Register Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(buttonColor)
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
        appSession.clubStore.allClubs.first { $0.id == event.clubId }?.name ?? "Technojam"
    }
    
    private var registrationProgress: Double {
        guard event.maxParticipants > 0 else { return 0 }
        return min(Double(event.numberOfRegistrations) / Double(event.maxParticipants), 1.0)
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
