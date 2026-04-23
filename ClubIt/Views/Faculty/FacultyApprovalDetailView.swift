import SwiftUI

struct FacultyApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    let approval: Approval
    
    @State private var remark: String = ""
    @State private var showingConfirmation: Bool = false
    @State private var showingRemarkPrompt: Bool = false
    @State private var targetStatus: ApprovalStatus = .pending
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                    // Event Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(event.name)
                            .font(.title.bold())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "calendar", title: "Date", value: formatDate(event.startDate))
                            InfoRow(icon: "mappin.and.ellipse", title: "Location", value: event.location)
                            InfoRow(icon: "person.2.fill", title: "Organizer", value: appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })?.name ?? "Club")
                        }
                        
                        Divider()
                        
                        Text("Description")
                            .font(.headline)
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 24))
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            targetStatus = .rejected
                            remark = "" // Reset remark
                            showingRemarkPrompt = true
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Reject")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundColor(.red)
                            .glassEffect(in: .rect(cornerRadius: 16))
                        }
                        
                        Button(action: {
                            targetStatus = .approved
                            showingConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Approve")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.opacity(0.1))
                            .foregroundColor(.green)
                            .glassEffect(in: .rect(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Review Proposal")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirm Action", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(targetStatus == .approved ? "Approve" : "Reject", role: targetStatus == .approved ? .none : .destructive) {
                appSession.approvalStore.updateApproval(id: approval.id, status: targetStatus, remark: remark)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to \(targetStatus == .approved ? "approve" : "reject") this event proposal?")
        }
        .sheet(isPresented: $showingRemarkPrompt) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Rejection Remark")
                    .font(.headline)
                
                TextEditor(text: $remark)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                Text("Please provide a reason for rejecting this proposal.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Cancel") {
                        showingRemarkPrompt = false
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Submit Rejection") {
                        appSession.approvalStore.updateApproval(id: approval.id, status: .rejected, remark: remark)
                        showingRemarkPrompt = false
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(remark.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .bold()
            }
        }
    }
}

#Preview {
    let session = MockData.session(for: .faculty)
    let approval = session.approvalStore.approvals.first
    return NavigationStack {
        if let approval = approval {
            FacultyApprovalDetailView(approval: approval)
                .environment(session)
        } else {
            Text("No approval found")
        }
    }
}
