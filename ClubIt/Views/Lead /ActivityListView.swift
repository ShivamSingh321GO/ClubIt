//
//  ActivityListView.swift
//  ClubIt
//

import SwiftUI

struct ActivityListView: View {
    @Environment(AppSession.self) var appSession
    @State private var showingAddActivity = false
    @State private var selectedActivity: Activity? = nil
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if appSession.activityStore.activities.isEmpty {
                    ContentUnavailableView("No Activities", systemImage: "calendar.badge.exclamationmark", description: Text("Start adding activities for your club members."))
                        .padding(.top, 40)
                } else {
                    ForEach(appSession.activityStore.activities) { activity in
                        ActivityCard(activity: activity) { tappedActivity in
                            selectedActivity = tappedActivity
                        }
                            .contextMenu {
                                if appSession.currentRole == .clubLead {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            appSession.activityStore.deleteActivity(activity)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if appSession.currentRole == .clubLead {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityFormView()
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity)
                .environment(appSession)
//                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    NavigationStack {
        ActivityListView()
            .environment(MockData.session(for: .clubLead))
    }
}
