import SwiftUI
import ClubItShared

struct MockNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: String
    let icon: String
    let color: Color
    var isRead: Bool
}

struct LeadNotificationView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var notifications: [MockNotification] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("We'll let you know when something important happens.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List {
                        ForEach(notifications) { item in
                            NotificationRow(notification: item)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let idx = notifications.firstIndex(where: { $0.id == item.id }) {
                                        notifications[idx].isRead = true
                                    }
                                }
                        }
                        .onDelete(perform: deleteNotification)
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 14, weight: .bold))
//                            .foregroundColor(.primary)
//                            .padding(8)
//                            .background(Color.primary.opacity(0.06))
//                            .clipShape(Circle())
//                    }
//                }
                
//                if !notifications.isEmpty {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Button("Mark all read") {
//                            for idx in notifications.indices {
//                                notifications[idx].isRead = true
//                            }
//                        }
//                        .font(.subheadline.bold())
//                        .foregroundColor(.blue)
//                    }
//                }
            }
        }
    }
    
    private func deleteNotification(at offsets: IndexSet) {
        notifications.remove(atOffsets: offsets)
    }
}

struct NotificationRow: View {
    let notification: MockNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Badge
            ZStack {
                Circle()
                    .fill(notification.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(notification.color)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(notification.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.trailing, 8)
            }
            
            // Unread Dot
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    LeadNotificationView()
}
