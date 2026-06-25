//
//  ClubCardView.swift
//  ClubIt
//
//  Created by Aryan on 3/25/26.
//

import SwiftUI
import ClubItShared

struct ClubCard: View {
    let club: Club
    @Environment(AppSession.self) private var appSession
    
    var isFollowing: Bool {
        appSession.clubStore.followedClubIds.contains(club.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .top, spacing: 14) {
                
                ClubLogoView(logo: club.logo, imageData: club.imageData, size: 50, iconSize: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(appSession.clubStore.allUsers.filter { $0.clubId == club.id }.count) Members")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Top Right Category Badge
                Text(club.category.rawValue.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(club.tagLine ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Text(club.description ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120, alignment: .topLeading)
        .contentShape(Rectangle()) // Makes the entire area tappable
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
