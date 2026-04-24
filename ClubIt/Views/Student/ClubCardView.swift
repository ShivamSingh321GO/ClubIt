//
//  ClubCardView.swift
//  ClubIt
//
//  Created by Aryan on 3/25/26.
//

import SwiftUI

struct ClubCard: View {
    let club: Club
    @Environment(AppSession.self) private var appSession
    
    var isFollowing: Bool {
        appSession.clubStore.followedClubIds.contains(club.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .top, spacing: 14) {
                
                // Club Logo
                ZStack {
                    Circle()
                    
                    Image(club.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(club.memberCount) Members")
                                .font(.caption2)
                        }
                        
                        Circle()
                            .fill(.secondary.opacity(0.5))
                            .frame(width: 3, height: 3)
                        
                        Text(club.category.rawValue.capitalized)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Follow Button
                Button {
                    appSession.clubStore.toggleFollow(for: club.id)
                } label: {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .glassEffect(in: .capsule)
                .scaleEffect(isFollowing ? 0.98 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFollowing)
                .foregroundStyle(isFollowing ? .blue : .primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(club.tagLine)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Text(club.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120, alignment: .topLeading)
        .glassEffect(in: .rect(cornerRadius: 20))
        
    }
}


#Preview("ClubCard") {
    // Sample data for preview
    let sampleClub = Club(
        id: UUID(),
        name: "SwiftUI Builders",
        tagLine: "Build beautiful apps together",
        description: "A community of iOS developers exploring SwiftUI, Combine, and Swift Concurrency. We host weekly meetups, code reviews, and open-source collaborations.",
        category: .technical,
        logo: "quizzards_logo",
        clubLeadId: UUID(),
        facultyId: UUID(),
        vicePresidentId: MockData.unassignedVPId,

        instituteId: UUID(),
        status: .active,
        createdAt: Date(),
        memberCount: 150,
        eventCount: 8,
        socials: [:]
    )
    
    // AppSession for previewing
    let session = AppSession()
    
    ClubCard(club: sampleClub)
        .environment(session)
        .padding()
}
