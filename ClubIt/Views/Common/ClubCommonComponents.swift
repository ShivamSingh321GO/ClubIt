import SwiftUI

struct StatBadge: View {
    let icon: String
    let count: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .center, spacing: 0) {
                Text(count)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(color.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SocialCircle: View {
    let platform: String

    var iconName: String {
        switch platform.lowercased() {
        case "instagram": return "instagramLogo"
        case "facebook": return "facebookLogo"
        case "linkedin": return "linkedInLogo"
        case "whatsapp": return "whatsappLogo"
        case "discord": return "discordLogo"
        default: return "globe"
        }
    }

    var body: some View {
        HStack {
            Image(iconName)
                .resizable()
                .frame(width: 50, height: 50)
                .font(.headline)
        }
    }
}

struct LocalAnnouncementCard: View {
    let announcement: Announcement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "megaphone.fill")
                            .foregroundStyle(.goldenBrown)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(relativeTimeText(from: announcement.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            if !announcement.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(announcement.url)
                    .font(.callout)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private func relativeTimeText(from date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        let minutes = diff / 60
        let hours = diff / 3600
        let days = diff / 86400

        if minutes < 1 { return "0 minutes ago" }
        if minutes < 60 { return "\(minutes) minutes ago" }
        if hours < 24 { return "\(hours) hours ago" }
        return "\(days) days ago"
    }
}

struct MediaButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(5)
        .frame(width: 80)
    }
}
