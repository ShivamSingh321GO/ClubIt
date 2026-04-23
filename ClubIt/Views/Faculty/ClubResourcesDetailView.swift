import SwiftUI

struct ClubResourcesDetailView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    @State private var selectedTab: String = "Resources"
    @State private var selectedResourceForRemark: Resource?
    @State private var selectedVenueApprovalForRemark: Approval?
    
    @State private var showingResourceApprovalAlert = false
    @State private var resourceToApprove: Resource?
    
    @State private var showingVenueApprovalAlert = false
    @State private var venueToApprove: Approval?
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        let allClubResources = appSession.approvalStore.resources.filter { clubEventIds.contains($0.eventId) }
        let allClubVenueApprovals = appSession.approvalStore.approvals.filter { 
            clubEventIds.contains($0.eventId) && $0.type == .venue 
        }
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Club Header
                ClubHeaderView(club: club, pendingResources: allClubResources)
                
                // Global Requested At
                GlobalTimestampView(resources: allClubResources)
                
                // MARK: - Segmented Filter
                SegmentedTabView(selectedTab: $selectedTab, resourceCount: allClubResources.count, venueCount: allClubVenueApprovals.count)
                
                // MARK: - Content List
                if selectedTab == "Resources" {
                    ResourceListView(
                        resources: allClubResources,
                        onReject: { resource in
                            selectedResourceForRemark = resource
                        },
                        onApprove: { resource in
                            resourceToApprove = resource
                            showingResourceApprovalAlert = true
                        }
                    )
                } else {
                    VenueListView(
                        approvals: allClubVenueApprovals,
                        onReject: { approval in
                            selectedVenueApprovalForRemark = approval
                        },
                        onApprove: { approval in
                            venueToApprove = approval
                            showingVenueApprovalAlert = true
                        }
                    )
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedResourceForRemark) { resource in
            FacultyRemarkSheet(resource: resource)
        }
        .sheet(item: $selectedVenueApprovalForRemark) { approval in
            FacultyVenueRemarkSheet(approval: approval)
        }
        .alert("Confirm Approval", isPresented: $showingResourceApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let resource = resourceToApprove {
                    withAnimation {
                        appSession.approvalStore.updateResourceStatus(id: resource.id, status: .approved)
                    }
                }
            }
        } message: {
            if let resource = resourceToApprove {
                Text("Are you sure you want to approve the request for '\(resource.name)'?")
            }
        }
        .alert("Confirm Approval", isPresented: $showingVenueApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let approval = venueToApprove {
                    withAnimation {
                        appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                    }
                }
            }
        } message: {
            if let approval = venueToApprove,
               let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                Text("Are you sure you want to approve the venue booking for '\(event.location)'?")
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Subviews
struct ClubHeaderView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    let pendingResources: [Resource]
    
    var body: some View {
        let pendingItems = pendingResources.filter { $0.status == .pending }
        if let firstEventId = pendingItems.first?.eventId,
           let event = appSession.eventStore.events.first(where: { $0.id == firstEventId }) {
            NavigationLink(destination: EventDetailView(event: event, isMyEvent: false)) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(club.name.prefix(1)))
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(club.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary.opacity(0.3))
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(club.name.prefix(1)))
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name)
                        .font(.title3.bold())
                    Text("Manage resource requests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
}

struct GlobalTimestampView: View {
    let resources: [Resource]
    
    var body: some View {
        if let firstRequest = resources.sorted(by: { $0.createdAt > $1.createdAt }).first {
            HStack {
                Image(systemName: "clock.fill")
                Text("Requested on \(formatDate(firstRequest.createdAt))")
            }
            .font(.caption.bold())
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, -8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SegmentedTabView: View {
    @Binding var selectedTab: String
    let resourceCount: Int
    let venueCount: Int
    
    var body: some View {
        Picker("Select Category", selection: $selectedTab) {
            Text("Resources (\(resourceCount))").tag("Resources")
            Text("Venue (\(venueCount))").tag("Venue")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

struct ResourceListView: View {
    let resources: [Resource]
    let onReject: (Resource) -> Void
    let onApprove: (Resource) -> Void
    
    var body: some View {
        if resources.isEmpty {
            EmptyStateView(icon: "tray", message: "No resource requests found")
        } else {
            VStack(spacing: 16) {
                ForEach(resources.sorted(by: { $0.createdAt > $1.createdAt })) { resource in
                    FacultyResourceRequestCard(
                        resource: resource,
                        onReject: { onReject(resource) },
                        onApprove: { onApprove(resource) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct VenueListView: View {
    let approvals: [Approval]
    let onReject: (Approval) -> Void
    let onApprove: (Approval) -> Void
    
    var body: some View {
        if approvals.isEmpty {
            EmptyStateView(icon: "mappin.and.ellipse", message: "No venue requests found")
        } else {
            VStack(spacing: 16) {
                ForEach(approvals.sorted(by: { $0.createdAt > $1.createdAt })) { approval in
                    FacultyVenueApprovalCard(
                        approval: approval,
                        onReject: { onReject(approval) },
                        onApprove: { onApprove(approval) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }


// Re-using the improved card but with a rejection callback
struct FacultyResourceRequestCard: View {
    @Environment(AppSession.self) var appSession
    let resource: Resource
    let onReject: () -> Void
    let onApprove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Title and Status
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: "cube.box.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text(resource.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                FacultyStatusBadge(status: resource.status)
            }
            
            Divider().opacity(0.3)
            
            // MARK: - Resource Details Grid
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 20) {
                    FacultyDetailItem(icon: "number.circle.fill", label: "Quantity", value: "\(resource.quantity)")
                    FacultyDetailItem(icon: "tag.fill", label: "Source", value: resource.type == .university ? "University" : "External Rental")
                }
                
                if resource.type == .external {
                    HStack(alignment: .top, spacing: 20) {
                        if let cost = resource.cost {
                            FacultyDetailItem(icon: "indianrupeesign.circle.fill", label: "Rental Cost", value: "₹\(String(format: "%.0f", cost))")
                        }
                        if let vendor = resource.vendorName {
                            FacultyDetailItem(icon: "building.2.fill", label: "Vendor", value: vendor)
                        }
                    }
                }
                
                HStack(alignment: .top, spacing: 20) {
                    if let approvedAt = resource.approvedAt {
                        FacultyDetailItem(icon: "checkmark.shield.fill", label: "Status Updated", value: formatDate(approvedAt))
                    }
                }
                
                if let remark = resource.remark, !remark.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(remark)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .italic()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // MARK: - Action Buttons
            if resource.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark.circle")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FacultyVenueApprovalCard: View {
    @Environment(AppSession.self) var appSession
    let approval: Approval
    let onReject: () -> Void
    let onApprove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.purple)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Venue Booking")
                            .font(.headline)
                        if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                            Text(event.location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                FacultyApprovalStatusBadge(status: approval.status)
            }
            
            Divider().opacity(0.3)
            
            VStack(alignment: .leading, spacing: 12) {
                if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                    HStack(alignment: .top, spacing: 20) {
                        FacultyDetailItem(icon: "calendar", label: "Event Date", value: formatDateShort(event.startDate))
                        FacultyDetailItem(icon: "checkmark.circle.fill", label: "Availability", value: "Confirmed Available")
                    }
                    
                    HStack(alignment: .top, spacing: 20) {
                        FacultyDetailItem(icon: "clock", label: "Duration", value: "\(formatTime(event.startTime)) - \(formatTime(event.endTime))")
                    }
                }
                
                if let remark = approval.remark, !remark.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(remark)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .italic()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            if approval.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark.circle")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.bold())
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white : Color.clear)
            .foregroundColor(isSelected ? .blue : .secondary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? .black.opacity(0.05) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

struct FacultyApprovalStatusBadge: View {
    let status: ApprovalStatus
    
    var color: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct FacultyVenueRemarkSheet: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    let approval: Approval
    @State private var remark: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add a remark for Venue rejection")
                    .font(.headline)
                
                TextEditor(text: $remark)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                Spacer()
                
                Button(action: {
                    appSession.approvalStore.updateApproval(id: approval.id, status: .rejected, remark: remark)
                    dismiss()
                }) {
                    Text("Reject with Remark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .disabled(remark.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .navigationTitle("Rejection Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}



struct FacultyStatusBadge: View {
    let status: ResourceStatus
    
    var color: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .issued: return .blue
        case .returned: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct FacultyDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FacultyRemarkSheet: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    let resource: Resource
    @State private var remark: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add a remark for \(resource.name)")
                    .font(.headline)
                
                TextEditor(text: $remark)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                Text("Please explain why this resource request is being rejected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    appSession.approvalStore.updateResourceStatus(id: resource.id, status: .rejected, remark: remark)
                    dismiss()
                }) {
                    Text("Reject with Remark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .disabled(remark.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .navigationTitle("Rejection Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClubResourcesDetailView(club: MockData.technoJamClub)
            .environment(MockData.session(for: .faculty))
    }
}
