import SwiftUI

struct PresidentAssignClubView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Select a Vice President to assign them new clubs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        let vicePresidents = MockData.allMockUsers.filter { $0.role == .vicePresident }
                        ForEach(vicePresidents) { vp in
                            let assignedClubs = appSession.clubStore.allClubs.filter { $0.vicePresidentId == vp.id }
                            
                            NavigationLink(destination: VPClubAssignmentDetailView(vp: vp)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        Text(String(vp.name.prefix(1))).bold()
                                            .foregroundColor(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vp.name)
                                            .font(.body.bold())
                                            .foregroundColor(.primary)
                                        Text("\(assignedClubs.count) clubs currently overseen")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Assign Club")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VPClubAssignmentDetailView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    let vp: User
    
    @State private var selectedClubs: Set<UUID> = []
    @State private var showingSuccessAlert = false
    
    init(vp: User) {
        self.vp = vp
        // In reality, we'd need to set the initial state in onAppear or similar
        // since we can't easily access appSession in init for a @State
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // VP Info Header
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(Text(String(vp.name.prefix(1))).font(.title2.bold()).foregroundColor(.orange))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vp.name)
                        .font(.title3.bold())
                    Text("Vice President")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.05))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Select the clubs you want \(vp.name) to oversee. You can select multiple clubs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(appSession.clubStore.allClubs) { club in
                        Button(action: {
                            if selectedClubs.contains(club.id) {
                                selectedClubs.remove(club.id)
                            } else {
                                selectedClubs.insert(club.id)
                            }
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    let firstLetter = String(club.name.prefix(1))
                                    Text(firstLetter).font(.caption.bold())
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(club.name)
                                        .font(.body.bold())
                                        .foregroundColor(.primary)
                                    
                                    if club.vicePresidentId == vp.id {
                                        Text("Currently Assigned")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.orange)
                                    } else if club.vicePresidentId != MockData.unassignedVPId {
                                        let otherVPId = club.vicePresidentId
                                        if let otherVP = MockData.allMockUsers.first(where: { $0.id == otherVPId }) {
                                            Text("Assigned to \(otherVP.name)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: selectedClubs.contains(club.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedClubs.contains(club.id) ? .orange : .secondary)
                                    .font(.title3)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedClubs.contains(club.id) ? Color.orange.opacity(0.05) : Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedClubs.contains(club.id) ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Assign Club")
        .onAppear {
            // Set initial selection to clubs already assigned to this VP
            selectedClubs = Set(appSession.clubStore.allClubs.filter { $0.vicePresidentId == vp.id }.map { $0.id })
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: saveAssignments) {
                    Image(systemName: "checkmark")
                        .font(.headline)
                }
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Clubs successfully assigned to \(vp.name).")
        }
    }
    
    private func saveAssignments() {
        for i in 0..<appSession.clubStore.allClubs.count {
            let clubId = appSession.clubStore.allClubs[i].id
            if selectedClubs.contains(clubId) {
                appSession.clubStore.allClubs[i].vicePresidentId = vp.id
            } else if appSession.clubStore.allClubs[i].vicePresidentId == vp.id {
                // If it was assigned to this VP but now unselected, remove it
                appSession.clubStore.allClubs[i].vicePresidentId = MockData.unassignedVPId
            }
        }
        showingSuccessAlert = true
    }
}

#Preview {
    PresidentAssignClubView()
        .environment(MockData.session(for: .president))
}
