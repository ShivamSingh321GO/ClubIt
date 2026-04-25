import SwiftUI

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(activity.type.rawValue.uppercased())
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(activity.type.color.opacity(0.2))
                                .foregroundColor(activity.type.color)
                                .clipShape(Capsule())
                            
                            Spacer()
                        }
                        
                        Text(activity.title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                    }
                    .padding(24)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "doc.text.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(activity.description)
                            .font(.body)
                            .lineSpacing(6)
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(in: .rect(cornerRadius: 20))
                    }
                    
                    // Location Section
                    if let location = activity.location {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Location", systemImage: "mappin.and.ellipse")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "building.2.fill")
                                    .font(.title2)
                                    .foregroundColor(activity.type.color)
                                    .frame(width: 50, height: 50)
                                    .background(activity.type.color.opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(location)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(16)
                            .glassEffect(in: .rect(cornerRadius: 20))
                        }
                    }
                    
                    // Timeline & Meta Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Activity Details", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 16) {
                            metaRow(icon: "person.circle.fill", label: "Posted By", value: activity.postedByName ?? "Unknown", color: .blue)
                            
                            Divider()
                            
                            metaRow(icon: "clock.fill", label: "Created At", value: formattedDate(activity.createdAt), color: .orange)
                        }
                        .padding(20)
                        .glassEffect(in: .rect(cornerRadius: 20))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if appSession.currentRole == .clubLead {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("Delete")
                                .foregroundColor(.red)
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
                    withAnimation {
                        appSession.activityStore.deleteActivity(activity)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this activity? This action cannot be undone.")
            }
        }
    }
    
    private func metaRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
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
    ActivityDetailView(activity: Activity(
        type: .workshop,
        title: "SwiftUI Advanced Patterns",
        description: "An in-depth session on using the new Observation framework, custom transitions, and complex layouts in SwiftUI 5.0.",
        date: Date().addingTimeInterval(86400),
        location: "Block C, Room 204",
        clubId: UUID(),
        postedBy: UUID(),
        postedByName: "Aryan Srivastava",
        createdAt: Date()
    ))
}
