//
//  EventCardView.swift
//  ClubIt
//
//  Created by Aryan on 3/25/26.
//

import SwiftUI

struct EventCardView: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            ZStack {
                if let bannerImage = event.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if bannerImage.lowercased().hasPrefix("http") {
                        AsyncImage(url: URL(string: bannerImage)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure(_):
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 280, height: 140)
                        .clipped()
                    } else {
                        Image(bannerImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 140)
                            .clipped()
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(width: 280, height: 140)
                    
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                Text("Hosted by \(appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })?.name ?? "Club")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Label(event.startDate.formatted(.dateTime.day().month()), systemImage: "calendar")
                    Label((event.startTime ?? event.startDate).formatted(.dateTime.hour().minute()), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Label(event.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                
                HStack {
                    Text("Registration :")
                        .font(.caption)
                        .bold()
                    
                    Text("\(event.numberOfRegistrations ?? 0)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(12)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}
