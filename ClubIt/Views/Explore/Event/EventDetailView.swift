import SwiftUI
import ClubItShared

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct BannerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 250
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    @State private var isShowingAttendanceQR = false
    @State private var isShowingScanner = false
    @State private var scrollOffset: CGFloat = 0
    @State private var bannerHeight: CGFloat = 250
    @State private var isDescriptionExpanded = false
    
    private var safeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first
        return window?.safeAreaInsets.top ?? 59
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. Background Fixed Poster Area
            VStack(spacing: 0) {
                // Spacer for the top status bar area to prevent overlap with status bar text
                Color.clear
                    .frame(height: safeAreaTop)
                
                // Fixed Poster banner (fully visible, scaled to fit)
                heroBanner
                    .scaledToFit()
                    .background(
                        GeometryReader { bannerGeo in
                            Color.clear.preference(
                                key: BannerHeightPreferenceKey.self,
                                value: bannerGeo.size.height
                            )
                        }
                    )
                
                Spacer()
            }
            .zIndex(0)
            
            // 2. ScrollView on top
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Transparent Spacer of safeAreaTop + bannerHeight to push detail sheet under background poster
                    Color.clear
                        .frame(height: safeAreaTop + bannerHeight)
                    
                    // Overlapping Content Sheet
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Title & Status
                        HStack(alignment: .top) {
                            Text(event.title)
                                .font(.title.bold())
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isMyEvent || event.status == .pending {
                                statusBadge
                            } else if appSession.registeredEventIds.contains(event.id) {
                                statusLabel(text: "Registered", color: .green)
                            }
                        }
                        .padding(.bottom, 12)
                        
                        // Description (About)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .lineLimit(isDescriptionExpanded ? nil : 3)
                            
                            if event.description.count > 150 || event.description.contains("\n") {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isDescriptionExpanded.toggle()
                                    }
                                }) {
                                    Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                        .font(.footnote.bold())
                                        .foregroundColor(.accentColor)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                        
                        Divider()
                        
                        // Quick Details
                        quickDetailsSection
                        
                        Divider()
                        
                        // Organizer
                        organizerSection
                        
                        // Agenda
                        if let agenda = event.agenda, !agenda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Divider()
                            agendaSection(agenda)
                        }
                        
                        // Registration Progress
                        if event.status != .pending && (event.isRegistrationOpen ?? true) {
                            Divider()
                            registrationSection
                        }
                        
                        // Pending Approval Button
                        if event.status == .pending {
                            if let role = appSession.currentUser?.role, role != .groupSubLead && role != .groupLead && role != .groupSubLead {
                                Divider()
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
                                .padding(.top, 24)
                            }
                        }
                        
                        // Action Buttons (Publish, Manage, Register Now) inside scroll view
                        if shouldShowStickyBottomBar {
                            Divider()
                            ctaButtonsSection
                                .padding(.top, 24)
                        }
                        
                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .zIndex(1)
                }
            }
            .zIndex(1)
        }
        .ignoresSafeArea(edges: .top)
        .onPreferenceChange(BannerHeightPreferenceKey.self) { value in
            self.bannerHeight = value
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarRole(.editor)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ready to Go Live?", isPresented: $isShowingPublishAlert) {
            Button("Publish Now", role: .none) {
                Task {
                    do {
                        try await appSession.eventStore.updateEventStatus(id: event.id, status: .published)
                        await appSession.chatStore.createEventChatsForPublishedEvent(event: event)
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
                    let success = await appSession.registerForEvent(id: event.id)
                    if success {
                        // Using a small delay to prevent alert stacking issues
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        appSession.showWithdrawSuccessAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to withdraw your registration? This will free up your slot.")
        }
        .alert("Withdrawal Successful", isPresented: Bindable(appSession).showWithdrawSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You have successfully withdrawn from this event. You have been removed from the event's chats.")
        }
        .sheet(isPresented: $isShowingRegistrationForm) {
            DynamicRegistrationFormView(event: event)
        }
        .sheet(isPresented: $isShowingAttendanceQR) {
            AttendanceQRDisplayView(event: event)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingScanner) {
            MarkAttendanceView(expectedEventId: event.id)
        }
    }
    
    // MARK: - Hero Banner
    
    private var heroBanner: some View {
        Group {
            if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if let banner = event.bannerImage, !banner.isEmpty {
                if banner.hasPrefix("http") {
                    AsyncImage(url: URL(string: banner)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            placeholderBanner
                        case .empty:
                            ZStack {
                                Color.accentColor.opacity(0.05)
                                ProgressView()
                            }
                        @unknown default:
                            placeholderBanner
                        }
                    }
                } else {
                    Image(banner)
                        .resizable()
                        .scaledToFit()
                }
            } else {
                placeholderBanner
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var placeholderBanner: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16/9, contentMode: .fit)
    }
    
    // MARK: - Row Builders (F1 Style)
    
    private func detailRow<Content: View>(icon: String, bottomText: String, @ViewBuilder topContent: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                topContent()
                Text(bottomText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }

    private func detailRow(icon: String, topText: String, bottomText: String) -> some View {
        detailRow(icon: icon, bottomText: bottomText) {
            Text(topText)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func infoRow(icon: String, title: String, content: AnyView) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundColor(.primary)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                content
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Sections
    
    private var quickDetailsSection: some View {
        VStack(spacing: 0) {
            detailRow(icon: "calendar", bottomText: "Date & Time") {
                dateAndTimeContentView
            }
            Divider()
            detailRow(icon: "mappin.and.ellipse", topText: event.location, bottomText: "Venue")
        }
    }
    
    private var organizerSection: some View {
        let matchingSubgroup = appSession.subgroupStore.allSubgroups.first { subgroup in
            if let subgroupIds = event.subgroupIds {
                return subgroupIds.contains(subgroup.id)
            }
            return subgroup.id == event.subgroupId
        }
        
        let label = event.subgroupId == nil ? "Associated Subgroups" : "Hosted by"
        
        return Group {
            if let subgroup = matchingSubgroup {
                NavigationLink(destination: SubgroupDetailView(subgroup: subgroup)) {
                    detailRow(icon: "person.crop.rectangle", topText: organizerName, bottomText: label)
                }
                .buttonStyle(.plain)
            } else {
                detailRow(icon: "person.crop.rectangle", topText: organizerName, bottomText: label)
            }
        }
    }
    
    private func agendaSection(_ agenda: String) -> some View {
        let lines = agenda.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return infoRow(icon: "list.bullet.indent", title: "Agenda", content: AnyView(
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    Text("• " + line)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        ))
    }
    
    private var registrationSection: some View {
        let registrations = appSession.registrationStore.getRegistrations(for: event.id)
        let topText = event.maxParticipants >= 999999 ? "\(registrations.count) Registered" : "\(registrations.count) / \(event.maxParticipants)"
        let bottomText = "Registrations"
        
        return HStack(alignment: .center, spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(topText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(bottomText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Action Buttons Section
    
    private var ctaButtonsSection: some View {
        VStack(spacing: 12) {
            if isMyEvent {
                if event.status == .approved {
                    Button {
                        isShowingPublishAlert = true
                    } label: {
                        Text("Publish Event")
                            .font(.headline.bold())
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.primary)
                } else {
                    HStack(spacing: 12) {
                        Button {
                            isShowingAttendanceQR = true
                        } label: {
                            Image(systemName: "qrcode")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(.purple)
                        
                        NavigationLink(destination: ManageParticipantsView(event: event)) {
                            Text("Manage")
                                .font(.headline.bold())
                                .foregroundColor(Color(.systemBackground))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .tint(.primary)
                    }
                }
            } else if appSession.currentRole == .groupSubLead || appSession.currentRole == .admin || appSession.currentRole == .groupLead || appSession.currentRole == .groupSubLead {
                EmptyView()
            } else {
                let isRegistered = appSession.registeredEventIds.contains(event.id)
                let isFull = event.maxParticipants > 0 && event.maxParticipants < 999999 && appSession.registrationStore.getRegistrations(for: event.id).count >= event.maxParticipants
                let isOpen = event.isRegistrationOpen ?? true
                
                HStack(spacing: 12) {
                    if canScanAttendance {
                        Button {
                            isShowingScanner = true
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(.green)
                    }
                    
                    if isRegistered {
                        Button {
                            isShowingWithdrawConfirmAlert = true
                        } label: {
                            Text("Withdraw")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .tint(.red)
                    } else if !isOpen {
                        Button(action: {}) {
                            Label("Registration Closed", systemImage: "lock.fill")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .tint(.secondary)
                        .disabled(true)
                    } else if isFull {
                        Button(action: {}) {
                            Label("Event Full", systemImage: "person.crop.circle.badge.xmark")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
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
                                .font(.headline.bold())
                                .foregroundColor(Color(.systemBackground))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .tint(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Utilities
    
    private var shouldShowStickyBottomBar: Bool {
        if event.status == .pending {
            return false
        }
        if isMyEvent {
            return true
        }
        if appSession.currentRole == .groupSubLead || appSession.currentRole == .admin || appSession.currentRole == .groupLead || appSession.currentRole == .groupSubLead {
            return false
        }
        return true
    }
    
    private func statusLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let status = event.status
        let color: Color = {
            switch status {
            case .pending: return .accentColor
            case .approved: return .green
            default: return .blue
            }
        }()
        
        let text: String = {
            switch status {
            case .pending: return "Pending"
            case .approved: return "Approved"
            default: return status.rawValue.capitalized
            }
        }()
        
        statusLabel(text: text, color: color)
    }
    
    private var dateAndTimeContentView: some View {
        let calendar = Calendar.current
        let isSameDay = calendar.isDate(event.startDate, inSameDayAs: event.endDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        return Group {
            if isSameDay {
            let dateStr = dateFormatter.string(from: event.startDate)
            let startTimeStr = timeFormatter.string(from: event.startTime ?? event.startDate)
            let endTimeStr = event.endTime != nil ? timeFormatter.string(from: event.endTime!) : timeFormatter.string(from: event.endDate)
            
            Text("\(dateStr) • \(startTimeStr) - \(endTimeStr)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            let startDateStr = dateFormatter.string(from: event.startDate)
            let endDateStr = dateFormatter.string(from: event.endDate)
            let startTimeStr = timeFormatter.string(from: event.startTime ?? event.startDate)
            let endTimeStr = event.endTime != nil ? timeFormatter.string(from: event.endTime!) : timeFormatter.string(from: event.endDate)
            
            let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: event.startDate), to: calendar.startOfDay(for: event.endDate))
            let days = (components.day ?? 0) + 1
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(startDateStr)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(startTimeStr)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("\(days) Days")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(endDateStr)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(endTimeStr)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        }
    }
    
    private var organizerName: String {
        if let subgroupIds = event.subgroupIds, !subgroupIds.isEmpty {
            let names = subgroupIds.compactMap { id in appSession.subgroupStore.allSubgroups.first(where: { $0.id == id })?.name }
            return names.joined(separator: ", ")
        }
        if let subgroupId = event.subgroupId {
            return appSession.subgroupStore.allSubgroups.first { $0.id == subgroupId }?.name ?? "Event Organizer"
        }
        return "Group Event"
    }
    
    private var canScanAttendance: Bool {
        let calendar = Calendar.current
        var finalEndDate = event.endDate
        if let endTime = event.endTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            finalEndDate = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: event.endDate) ?? event.endDate
        }
        return Date() <= finalEndDate.addingTimeInterval(2 * 3600)
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: MockData.technoJamBundle.events[0], isMyEvent: false)
            .environment(MockData.session(for: .guest))
    }
}
