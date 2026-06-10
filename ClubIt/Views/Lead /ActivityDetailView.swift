import SwiftUI

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var showingDeleteAlert = false
    
    private var postedByName: String {
        if activity.postedBy == appSession.currentUser?.id { return "You" }
        return appSession.clubStore.allUsers.first(where: { $0.id == activity.postedBy })?.name ?? "Unknown"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            typeBadge
                            Spacer()
                        }
                        
                        Text(activity.title)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.primary)
                            
                        Divider().padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(title: "Description", icon: "doc.text.fill")
                        
                        Text(activity.description)
                            .font(.body)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Divider().padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Location Section
                    if let location = activity.location {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(title: "Location", icon: "mappin.and.ellipse")
                            
                            HStack(spacing: 16) {
                                Image(systemName: "building.2.fill")
                                    .font(.title2)
                                    .foregroundStyle(activity.type.color)
                                    .frame(width: 44, height: 44)
                                    .background(activity.type.color.opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(location)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                            }
                            
                            Divider().padding(.top, 12)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Timeline & Meta Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Activity Details", icon: "info.circle.fill")
                        
                        VStack(spacing: 16) {
                            detailRow(icon: "person.circle.fill", label: "Posted By", value: postedByName, color: .blue)
                            detailRow(icon: "clock.fill", label: "Created At", value: formattedDate(activity.createdAt), color: .orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if appSession.currentRole == .clubLead {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("Delete")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Activity", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await appSession.activityStore.deleteActivity(activity)
                            appSession.selectedActivity = nil
                            dismiss()
                        } catch {
                            print("DEBUG ERROR: Deletion failed: \(error.localizedDescription)")
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this activity? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Components
    
    private var typeBadge: some View {
        Text(activity.type.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(activity.type.color.opacity(0.2))
            .foregroundStyle(activity.type.color)
            .clipShape(Capsule())
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title.uppercased(), systemImage: icon)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
    
    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ActivityDetailView(activity: Activity(id: UUID(), type: .workshop,
        title: "SwiftUI Advanced Patterns",
        description: "An in-depth session on using the new Observation framework, custom transitions, and complex layouts in SwiftUI 5.0.",
        date: Date().addingTimeInterval(86400),
        location: "Block C, Room 204",
        clubId: UUID(),
        postedBy: UUID(),
        createdAt: Date()
    ))
}
