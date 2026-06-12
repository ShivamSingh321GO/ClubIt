//
//  ActivityCard.swift
//  ClubIt
//

import SwiftUI

struct ActivityCard: View {
    @Environment(AppSession.self) var appSession
    let activity: Activity
    var onTap: ((Activity) -> Void)? = nil
    
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
                // Header: Tag
                HStack {
                    Text(activity.type.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(activity.type.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(activity.type.color.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                
                // Content: Title and Description
                VStack(alignment: .leading, spacing: 4) {
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
                }
                
                // Location
                if let location = activity.location {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundColor(activity.type.color)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
                
//                Divider()
//                    .opacity(0.3)
//                    .padding(.vertical, 4)
                
                // Footer: Posted By and Date
                HStack {
                    if let postedByName = MockData.allMockUsers.first(where: { $0.id == activity.postedBy })?.name {
                        Label(postedByName, systemImage: "person.circle.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(formattedDate)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(activity)
        }
        
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: activity.createdAt)
    }
}

#Preview {
    ActivityCard(activity: Activity(id: UUID(), type: .workshop,
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
