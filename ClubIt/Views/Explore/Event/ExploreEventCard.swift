//
//  ExploreEventCard.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//

import SwiftUI
import ClubItShared

struct ExploreEventCard: View {
    @Environment(AppSession.self) var appSession
    
    let event: Event
    let isMyEvent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-bleed Banner Section
            bannerSection
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .center, endPoint: .bottom)
                )
                .overlay(alignment: .topTrailing) {
                    // Status Badge overlay
                    if isMyEvent || event.status == .pending {
                        statusBadge
                            .padding(12)
                    } else if appSession.registeredEventIds.contains(event.id) {
                        statusLabel(text: "Registered", color: .green)
                            .padding(12)
                    }
                }
                .overlay(alignment: .topLeading) {
                    categoryBadge
                        .padding(12)
                }
                .overlay(alignment: .bottomLeading) {
                    // Title
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(16)
                }
            
            // Content Section
            VStack(alignment: .leading, spacing: 16) {
                // Date, Time & Venue
                VStack(alignment: .leading, spacing: 16) {
                    // Date & Time
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.accentColor)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formattedShortDate)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(formattedTimeRange)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Venue
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.accentColor)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.location)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                    }
                }
                
                // Registration Info
                if event.isRegistrationOpen ?? true {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        let registeredCount = event.status == .pending ? 0 : appSession.registrationStore.getRegistrations(for: event.id).count
                        let maxParticipantsText = event.maxParticipants >= 999999 ? "\(registeredCount)" : "\(registeredCount) / \(event.maxParticipants)"
                        
                        Text("\(maxParticipantsText) Registrations")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.clear)
        .glassEffect(in: .rect(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var bannerSection: some View {
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
                                .background(Color.accentColor.opacity(0.1))
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
    }
    
    private var placeholderBanner: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.accentColor.opacity(0.5))
        }
    }
    
    private func statusLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
    
    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.system(size: 10, weight: .bold))
            Text(event.category.displayName)
                .font(.caption2.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.8))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
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
    
    // MARK: - Formatters
    
    private var hostName: String {
        if let subgroupIds = event.subgroupIds, !subgroupIds.isEmpty {
            let names = subgroupIds.compactMap { id in appSession.subgroupStore.allSubgroups.first(where: { $0.id == id })?.name }
            return names.joined(separator: ", ")
        }
        if let subgroupId = event.subgroupId {
            return appSession.subgroupStore.allSubgroups.first(where: { $0.id == subgroupId })?.name ?? "Organizer"
        }
        return "Group Event"
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
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        
        if start == end {
            return start
        } else {
            return "\(start) - \(end)"
        }
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
        formatter.dateFormat = "h a"
        
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
                subgroupId: UUID(),
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
        .background(Color.black)
    }
    .environment(AppSession())
}
