//
//  MemberHomeView.swift
//  ClubIt
//
//  Created by Ansh Srivastava on 3/29/26.
//

import SwiftUI

struct ClubMemberHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // All Tasks Section
                        HStack {
                            Text("All Tasks")
                            NavigationLink(destination: TasksListView(user: user)) {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.title2)
                        .bold()
                        
                        HomeTasksModule(user: user)
                        
                        // Registered Events Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Events registered")
                                .font(.title2)
                                .bold()
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(appSession.studentDashboardStore.registeredEvents) { event in
                                        NavigationLink(value: event) {
                                            EventCardView(event: event)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        ClubItCalendarView()
                            .padding(.top, 8)
                    }
                    .padding()
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            NavigationLink {
                                LeadNotificationView()
                            } label: {
                                Image(systemName: "bell")
                            }
                            
                            NavigationLink {
                                MemberProfileView()
                            } label: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
                    .navigationDestination(for: Event.self) { event in
                        EventDetailView(event: event, isMyEvent: false)
                    }
                }
            }
        }
        .sheet(item: Bindable(appSession).selectedTask) { task in
            TaskDetailView(task: task)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    ClubMemberHomeView()
        .environment(MockData.session(for: .clubMember))
}
