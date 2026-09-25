//
//  MySubgroupLead.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct LeadMySubgroupView: View {
    @Environment(AppSession.self) var appSession
    @State private var showEditSubgroup = false

    var user: User? {
        appSession.currentUser
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                SubgroupProfileBody(subgroup: appSession.subgroupStore.subgroup, startExpanded: false)
                    .padding(.vertical, 16)
            }
            .refreshable {
                await appSession.refreshData()
            }
            .navigationTitle("My \(appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup"))")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appSession.currentRole == .subGroupLead {
                        Button("Edit") {
                            showEditSubgroup = true
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showEditSubgroup) {
                EditSubgroupDetailView(subgroup: appSession.subgroupStore.subgroup)
            }
        }
        .sheet(item: Bindable(appSession).selectedActivity) { activity in
            ActivityDetailView(activity: activity)
                .environment(appSession)
                .presentationDetents([.medium, .large])
        }
        .task {
            await appSession.refreshData()
        }
    }
}

#Preview {
    let session = AppSession()
    session.currentRole = .subGroupLead
    session.currentUser = MockData.subgroupLeadUser
    return LeadMySubgroupView()
        .environment(session)
}
