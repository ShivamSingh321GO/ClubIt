//
//  MyClubLead.swift
//  ClubIt
//

import SwiftUI

struct LeadMyClubView: View {
    @Environment(AppSession.self) var appSession

    var user: User? {
        appSession.currentUser
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                ClubProfileBody(club: appSession.clubStore.club)
                    .padding(.vertical, 16)
            }
            .navigationTitle("My Club")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appSession.currentRole == .clubLead {
                        NavigationLink(
                            destination: EditClubDetailView(
                                club: appSession.clubStore.club
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
    }
}

#Preview {
    let session = AppSession()
    session.currentRole = .clubLead
    session.currentUser = MockData.clubLeadUser
    return LeadMyClubView()
        .environment(session)
}
