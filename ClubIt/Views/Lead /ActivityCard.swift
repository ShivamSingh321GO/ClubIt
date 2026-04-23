//
//  ActivityCard.swift
//  ClubIt
//

import SwiftUI

struct ActivityCard: View {
    @Environment(AppSession.self) var appSession
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon section
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: activity.type.icon)
                    .font(.title3.bold())
                    .foregroundColor(activity.type.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(activity.type.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(activity.type.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(activity.type.color.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(2)
                
                HStack(spacing: 12) {
                    if let location = activity.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let postedByName = activity.postedByName {
                        Label(postedByName, systemImage: "person.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [activity.type.color.opacity(0.1), activity.type.color.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .glassEffect(in: .rect(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: activity.date)
    }
}

#Preview {
    ActivityCard(activity: Activity(
        type: .workshop,
        title: "Deep Dive into SwiftUI 5.0",
        description: "Explaining the new observation framework and animation systems with practical examples.",
        date: Date(),
        location: "Lab 3, Ramanujan Block",
        clubId: UUID(),
        postedBy: UUID(),
        createdAt: Date()
    ))
    .environment(AppSession())
    
}
