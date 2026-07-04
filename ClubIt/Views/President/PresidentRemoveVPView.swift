import SwiftUI
import ClubItShared

struct PresidentRemoveVPView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Select a Vice President to remove their access from assigned subgroups.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        let vicePresidents = MockData.allMockUsers.filter { $0.role == .groupSubLead }
                        ForEach(vicePresidents) { vp in
                            let assignedSubgroups = appSession.subgroupStore.allSubgroups.filter { $0.vicePresidentId == vp.id }
                            
                            NavigationLink(destination: VPSubgroupRemovalDetailView(vp: vp)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        Text(String(vp.name.prefix(1))).bold()
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vp.name)
                                            .font(.body.bold())
                                            .foregroundColor(.primary)
                                        Text("\(assignedSubgroups.count) subgroups assigned")
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
            .navigationTitle("Remove Subgroup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VPSubgroupRemovalDetailView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    let vp: User
    
    @State private var selectedForRemoval: Set<UUID> = []
    @State private var showingSuccessAlert = false
    
    var body: some View {
        let assignedSubgroups = appSession.subgroupStore.allSubgroups.filter { $0.vicePresidentId == vp.id }
        
        VStack(alignment: .leading, spacing: 24) {
            // VP Info Header
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(Text(String(vp.name.prefix(1))).font(.title2.bold()).foregroundColor(.accentColor))
                
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
            .background(Color.accentColor.opacity(0.05))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Select the subgroups you want to remove from \(vp.name)'s oversight.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if assignedSubgroups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    Text("No subgroups assigned")
                        .font(.headline)
                    Text("This Vice President currently has no subgroup assignments.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(assignedSubgroups) { subgroup in
                            Button(action: {
                                if selectedForRemoval.contains(subgroup.id) {
                                    selectedForRemoval.remove(subgroup.id)
                                } else {
                                    selectedForRemoval.insert(subgroup.id)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Text(String(subgroup.name.prefix(1))).font(.caption.bold())
                                    }
                                    
                                    Text(subgroup.name)
                                        .font(.body.bold())
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedForRemoval.contains(subgroup.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedForRemoval.contains(subgroup.id) ? .red : .secondary)
                                        .font(.title3)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedForRemoval.contains(subgroup.id) ? Color.red.opacity(0.05) : Color.secondary.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedForRemoval.contains(subgroup.id) ? Color.red.opacity(0.2) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Remove Subgroup")
        .toolbar {
            if !selectedForRemoval.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: removeSelectedAccess) {
                        Image(systemName: "checkmark")
                            .font(.headline)
                    }
                }
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Selected subgroups have been successfully removed.")
        }
    }
    
    private func removeSelectedAccess() {
        for i in 0..<appSession.subgroupStore.allSubgroups.count {
            if selectedForRemoval.contains(appSession.subgroupStore.allSubgroups[i].id) {
                appSession.subgroupStore.allSubgroups[i].vicePresidentId = MockData.unassignedVPId
            }
        }
        showingSuccessAlert = true
    }
}

#Preview {
    PresidentRemoveVPView()
        .environment(MockData.session(for: .groupLead))
}
