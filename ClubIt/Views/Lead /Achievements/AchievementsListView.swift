//
//  AchievementsListView.swift
//  ClubIt
//

import SwiftUI

struct AchievementsListView: View {
    @Environment(AppSession.self) var appSession
    @State private var showCreateModal = false
    
    private var achievements: [Achievement] {
        appSession.clubAchievementStore.achievements
            .filter { $0.clubId == appSession.clubStore.club.id }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    private var awardCount: Int {
        achievements.filter { $0.type == .award }.count
    }
    
    private var milestoneCount: Int {
        achievements.filter { $0.type == .milestone }.count
    }
    
    private var recognitionCount: Int {
        achievements.filter { $0.type == .recognition }.count
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.goldenBrown.opacity(0.05))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "trophy.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Our Journey of Excellence")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        
                        Text("Celebrating milestones and achievements together")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        StatBox(value: awardCount, label: "Awards")
                        StatBox(value: milestoneCount, label: "Milestones")
                        StatBox(value: recognitionCount, label: "Recognition")
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .glassEffect(in: .rect(cornerRadius: 20))

                
                ForEach(achievements) { achievement in
                    AchievementCardView(achievement: achievement)
                        .contentShape(Rectangle())
                        .contextMenu {
                            if appSession.currentRole == .clubLead {
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            try await appSession.clubAchievementStore.deleteAchievement(achievement)
                                        } catch {
                                            print("DEBUG ERROR: Failed to delete achievement: \(error.localizedDescription)")
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .padding(16)
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appSession.currentRole == .clubLead {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateModal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateModal) {
            CreateAchievementView()
        }
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassEffect(in: .rect(cornerRadius: 12))
    }
}

#Preview {
    let session = AppSession()
    
    NavigationStack {
        AchievementsListView()
            .environment(session)
    }
}
