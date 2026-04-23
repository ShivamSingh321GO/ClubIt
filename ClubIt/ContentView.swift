//
//  ContentView.swift
//  ClubIt
//
//  Created by shivam kumar singh on 2/13/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    NavigationLink {
                        ClubAnnouncementListView()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Club announcement")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    AnnouncementCardView()
                }
                .padding()
            }
        }
    }
}

struct ClubAnnouncementListView: View {
    var body: some View {
        Text("Club Announcements")
            .navigationTitle("Club Announcement")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnnouncementCardView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(.systemGray6))
            .frame(height: 220)
            .overlay(
                Text("card view")
                    .foregroundStyle(.secondary)
            )
    }
}

#Preview {
    ContentView()
}


