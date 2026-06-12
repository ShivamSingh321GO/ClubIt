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
            ZStack(alignment: .bottomTrailing) {
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
            } // Close ScrollView
            
            NavigationLink(destination: ClubItCalendarView(standalone: true)) {
                Image(systemName: "calendar")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .glassEffect(in: .circle)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding()
        } // Close ZStack
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
