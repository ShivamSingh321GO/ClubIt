//
//  AchievementCardView.swift
//  ClubIt
//
//  Created by Ansh Srivastava on 3/24/26.
//

import SwiftUI

struct AchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: achievement.type.icon)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(achievement.createdAt, format: .dateTime.month().day().year())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(achievement.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

#Preview {
    AchievementCardView(
        achievement: Achievement(
            id: UUID(),
            clubId: UUID(),
            title: "Best Technical Club Award",
            description: "Recognized for exceptional performance, impactful events, and outstanding student engagement throughout the academic year.",
            type: .award,
            createdAt: .now
        )
    )
    .padding()
}
