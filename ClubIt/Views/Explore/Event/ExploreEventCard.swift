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
            
            VStack(alignment: .leading, spacing: 16) {
                // Title Section
                HStack(alignment: .center, spacing: 10) {
                    Text(event.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Action/Status Badge area
                    if isMyEvent || event.status == .pending {
                        // Show status label for my events or any pending event
                        statusBadge
                    } else if appSession.registeredEventIds.contains(event.id) {
                        // Show 'Registered' label for events user has joined
                        statusLabel(text: "Registered", color: .green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 16) {
                        // Date & Time Section
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "calendar")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DATE & TIME")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                Text(formattedShortDate)
                                    .font(.footnote.bold())
                                    .foregroundStyle(.primary)
                                Text(formattedTimeRange)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Venue Section
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(.orange.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("VENUE")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                Text(event.location)
                                    .font(.footnote.bold())
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Registration & Status Row
                    HStack(alignment: .center, spacing: 10) {
                        if event.isRegistrationOpen ?? true {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "person.2.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("REGISTRATIONS")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.secondary)
                                    let registeredCount = event.status == .pending ? 0 : appSession.registrationStore.getRegistrations(for: event.id).count
                                    Text(event.maxParticipants >= 999999 ? "\(registeredCount)" : "\(registeredCount) / \(event.maxParticipants)")
                                        .font(.footnote.bold())
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemBackground).opacity(0.4))
        .glassEffect(in: .rect(cornerRadius: 24))
        .padding(.vertical, 8)
    }
    
    private var bannerSection: some View {
        ZStack(alignment: .top) {
            Group {
                if let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let bannerImage = event.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if bannerImage.hasPrefix("http") {
                        AsyncImage(url: URL(string: bannerImage)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholderBanner
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.orange.opacity(0.05))
                            @unknown default:
                                placeholderBanner
                            }
                        }
                    } else {
                        Image(bannerImage)
                            .resizable()
                            .scaledToFill()
                    }
                } else {
                    placeholderBanner
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            
            // Calendar & Time Badge removed
        }
        .padding(6)
    }
    
    private var placeholderBanner: some View {
        ZStack {
            Color.orange.opacity(0.1)
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.orange.opacity(0.5))
        }
    }
    
    private func statusLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let status = event.status
        let color: Color = {
            switch status {
            case .pending: return .orange
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
    
    private var hostName: String {
        if let clubIds = event.clubIds, !clubIds.isEmpty {
            let names = clubIds.compactMap { id in appSession.clubStore.allClubs.first(where: { $0.id == id })?.name }
            return names.joined(separator: ", ")
        }
        if let clubId = event.clubId {
            return appSession.clubStore.allClubs.first(where: { $0.id == clubId })?.name ?? "Organizer"
        }
        return "Council Event"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: event.startDate)
    }
    
    private var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: event.startDate)
    }
    
    private var formattedShortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: event.startDate)
    }
    
    private var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.startDate).uppercased()
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startTime ?? event.startDate)
    }
    
    private var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a" // "12 PM"
        
        let start = formatter.string(from: event.startTime ?? event.startDate).replacingOccurrences(of: ":00", with: "")
        let end = formatter.string(from: event.endTime ?? event.endDate).replacingOccurrences(of: ":00", with: "")
        
        return "\(start) - \(end)"
    }
}

#Preview {
    NavigationStack {
        ExploreEventCard(
            event: Event(id: UUID(), name: "Open Mic Jam",
                title: "Open mic jam",
                description: "Sample event description",
                startDate: Date(),
                endDate: Date(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                numberOfVolunteers: 10,
                numberOfRegistrations: 100,
                maxParticipants: 150,
                registrationType: .individual,
                location: "C-Block",
                clubId: UUID(),
                createdBy: UUID(),
                category: .entertainment,
                status: .approved,
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
