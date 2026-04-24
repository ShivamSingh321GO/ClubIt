import SwiftUI

struct EventDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let event: Event
    let isMyEvent: Bool
    
    @State private var isShowingRegistrationForm = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                
                bannerSection
                
                VStack(alignment: .leading, spacing: 16) {
                    DetailIconRow(
                        icon: "calendar",
                        text: eventDateTimeText
                    )
                    
                    DetailIconRow(
                        icon: "mappin.and.ellipse",
                        text: event.location
                    )
                }
                
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.goldenBrown.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.headline)
                                .foregroundStyle(.goldenBrown)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Crafted by \(hostClubName)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Lead by \(leadName)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !isMyEvent {
                        Button {
                            //MARK: - banana hai isse
                            // redirect to the individual chat
                            
                            
                        } label: {
                            Image(systemName: "message")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Details")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.8))
                            .lineSpacing(2)
                    }
                    
                    if let agenda = event.agenda,
                       !agenda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Agenda")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(
                                    agenda
                                        .components(separatedBy: .newlines)
                                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                                    id: \.self
                                ) { line in
                                    AgendaItem(text: line)
                                }
                            }
                        }
                    }
                    
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registrations")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Text("\(event.numberOfRegistrations)/\(event.maxParticipants)")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.8))
                        
                        Spacer()
                        
                        Button {
                            if !isMyEvent {
                                if let form = event.registrationForm, !form.isEmpty {
                                    isShowingRegistrationForm = true
                                } else {
                                    appSession.registerForEvent(id: event.id)
                                }
                            }
                        } label: {
                            Text(isMyEvent ? "View Participants" : (appSession.registeredEventIds.contains(event.id) ? "Registered" : "Register"))
                                .font(.footnote.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(isMyEvent ? Color.blue : (appSession.registeredEventIds.contains(event.id) ? Color.green : Color.blue))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 20))
            .padding()
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingRegistrationForm) {
            DynamicRegistrationFormView(event: event)
        }
    }
    
    @ViewBuilder
    private var bannerSection: some View {
        if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } else if let bannerImage = event.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Image(bannerImage)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            placeholderBanner
        }
    }

    
    private var placeholderBanner: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var eventDateTimeText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let startTimeFormatter = DateFormatter()
        startTimeFormatter.dateFormat = "hh:mm a"
        
        let endTimeFormatter = DateFormatter()
        endTimeFormatter.dateFormat = "hh:mm a"
        
        return "\(dateFormatter.string(from: event.startDate)), \(startTimeFormatter.string(from: event.startTime)) - \(endTimeFormatter.string(from: event.endTime))"
    }
    
    private var hostClubName: String {
        "Technojam"
    }
    
    private var leadName: String {
        if isMyEvent {
            return appSession.currentUser?.name ?? "Club Lead"
        } else {
            return "Club Lead"
        }
    }
}

struct DetailIconRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 40, alignment: .center)
                .foregroundStyle(.primary)
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
        }
    }
}

struct AgendaItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body.bold())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.8))
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            event: Event(
                name: "Open Mic Jam",
                title: "Open Mic Jam",
                description: "A live performance event where students can sing, perform, and showcase talent.",
                startDate: Date(),
                endDate: Date(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(7200),
                numberOfVolunteers: 10,
                numberOfRegistrations: 150,
                maxParticipants: 200,
                registrationType: .individual,
                location: "C-Block",
                clubId: UUID(),
                createdBy: UUID(),
                category: .entertainment,
                status: .upcoming,
                registrationDeadline: Date(),
                bannerImage: "banner1",
                createdAt: Date()
            ),
            isMyEvent: false
        )
        .environment(MockData.session(for: .clubLead))
    }
}
