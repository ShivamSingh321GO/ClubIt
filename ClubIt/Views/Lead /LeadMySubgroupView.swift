//
//  MySubgroupLead.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct LeadMySubgroupView: View {
    @Environment(AppSession.self) var appSession

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
            .navigationTitle("My Subgroup")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appSession.currentRole == .subGroupLead {
                        NavigationLink(
                            destination: EditSubgroupDetailView(
                                subgroup: appSession.subgroupStore.subgroup
                            )
                        ) {
                            Text("Edit")
                        }
                    }
                }
            }
        }
        .sheet(item: Bindable(appSession).selectedActivity) { activity in
            ActivityDetailView(activity: activity)
                .environment(appSession)
                .presentationDetents([.large])
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
