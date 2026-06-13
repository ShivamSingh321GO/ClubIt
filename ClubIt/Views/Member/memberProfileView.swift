//
//  memberProfileView.swift
//  ClubIt
//
//  Created by Ansh Srivastava on 4/2/26.
//

import SwiftUI

struct MemberProfileView: View {
    @Environment(AppSession.self) private var appSession
    @State private var isLoading = false
    
    var body: some View {
        if let user = appSession.currentUser {
            List {
                // MARK: - Profile Header
                Section {
                    HStack(spacing: 16) {
                        UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 70)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(user.role.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - About
                Section("About") {
                    Text((user.bio?.isEmpty ?? true) ? "No bio provided" : (user.bio ?? "No bio provided"))
                        .font(.body)
                }
                
                // MARK: - Contact
                Section("Contact") {
                    Label(user.phoneNumber ?? "N/A", systemImage: "phone")
                    Label(user.course ?? "N/A", systemImage: "building.columns")
                    Label(user.year ?? "N/A", systemImage: "graduationcap")
                }
                
                // MARK: - Club
                Section("Club") {
                    if let clubId = user.clubId,
                       let club = appSession.clubStore.allClubs.first(where: { $0.id == clubId }) {
                        
                        HStack {
                            Text(club.name)
                            
                            Spacer()
                            
                            Text(user.role.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not part of any club")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Settings
                Section("Settings") {
                    
                    NavigationLink {
                        Text("Notifications Screen")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Change Password Screen")
                    } label: {
                        Label("Change Password", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button(role: .destructive) {
                        appSession.signOut()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EditProfileView(user: user)
                    } label: {
                        Text("Edit")
                    }
                }
            }
            .refreshable {
                try? await appSession.clubStore.fetchAllUsers()
            }
            .task {
                isLoading = true
                try? await appSession.clubStore.fetchAllUsers()
                isLoading = false
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        } else {
            ContentUnavailableView(
                "Please login to view profile",
                systemImage: "person.crop.circle.badge.exclamationmark"
            )
        }
    }
}

#Preview {
    NavigationStack {
        MemberProfileView()
            .environment(MockData.session(for: .clubMember))
    }
}
