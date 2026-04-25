//
//  ExploreEventCard.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//


import SwiftUI

struct ExploreEventCard: View {
    @Environment(AppSession.self) var appSession
    
    let event: Event
    let isMyEvent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            bannerSection
            
            VStack(alignment: .leading, spacing: 10) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Hosted by \(hostName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .frame(width: 20)
                        
                        Text(formattedDateAndTime)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(width: 20)
                        
                        Text(event.location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if event.status == .pending {
                    HStack {
                        Spacer()
                        statusBadge
                    }
                } else {
                    HStack {
                        HStack(spacing: 4) {
                            Text("Registration :")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("\(event.numberOfRegistrations)/\(event.maxParticipants)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if !isMyEvent {
                            Button {
                                appSession.registerForEvent(id: event.id)
                            } label: {
                                Text(appSession.registeredEventIds.contains(event.id) ? "Registered" : "Register")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(appSession.registeredEventIds.contains(event.id) ? Color.green : Color.blue)
                                    .clipShape(Capsule())
                            }
                        } else if appSession.currentRole != .student {
                            statusBadge
                        }
                    }
                }
            }
            .padding()
        }
        .glassEffect(in: .rect(cornerRadius: 20))
        .contentShape(Rectangle())
    }
    
    private var bannerSection: some View {
        Group {
            if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let bannerImage = event.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Image(bannerImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderBanner
            }
        }
        .frame(height: 180)

        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var placeholderBanner: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let status = event.status
        let color: Color = {
            switch status {
            case .pending: return .orange
            case .completed, .upcoming: return .green
            case .cancelled: return .red
            default: return .green
            }
        }()
        
        let text: String = {
            switch status {
            case .pending: return "Pending"
            case .upcoming: return "Approved"
            default: return status.rawValue.capitalized
            }
        }()
        
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
    }
    
    private var hostName: String {
        appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })?.name ?? "Club"
    }
    
    private var formattedDateAndTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        
        return "\(dateFormatter.string(from: event.startDate))   \(timeFormatter.string(from: event.startTime))"
    }
}

#Preview {
    NavigationStack {
        ExploreEventCard(
            event: Event(
                name: "Open Mic Jam",
                title: "Open mic jam",
                description: "Sample event description",
                startDate: Date(),
                endDate: Date(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                numberOfVolunteers: 10,
                numberOfRegistrations: 150,
                maxParticipants: 100,
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
            isMyEvent: true
        )
        .padding()
    }
    .environment(AppSession())
}
