import SwiftUI

struct ChatInfoView: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack(spacing: 24) {
                // Header Profile
                VStack(spacing: 16) {
                    if let icon = chat.icon, icon.contains("https") {
                        AsyncImage(url: URL(string: icon)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.15))
                                .frame(width: 100, height: 100)
                            
                            if let icon = chat.icon, !icon.isEmpty, icon.count > 3 {
                                Image(systemName: icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: chat.icon ?? "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text(chat.name)
                            .font(.title2.bold())
                        
                        if chat.type == .group || chat.type == .event {
                            Text("\(chat.participants.count + 2) Participants")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Clublead")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 24)
                

                
                // Profile Information (For Individuals)
                if chat.type == .individual {
                    VStack(alignment: .leading, spacing: 20) {

                        // Contact
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                profileRow(icon: "phone", title: "N/A")
                                Divider().padding(.leading, 50)
                                profileRow(icon: "building.columns", title: "B.Tech CSE")
                                Divider().padding(.leading, 50)
                                profileRow(icon: "graduationcap", title: "3rd Year")
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                            .padding(.horizontal)
                        }
                        
                        // Club
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Club")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Button(action: {}) {
                                HStack {
                                    Text("Technojam")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("Clublead")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Shared Media
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Shared Media")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<4) { index in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                                    )
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                // Participants (if Group/Event)
                if chat.type == .group || chat.type == .event {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Participants")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(0..<3) { index in
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                    
                                    Text("User \(index + 1)")
                                        .font(.body)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            Button(action: {}) {
                                Text("See All")
                                    .font(.body.bold())
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                        .padding(.horizontal)
                    }
                }
                
                // Destructive Actions
                VStack(spacing: 0) {
                    Button(action: {}) {
                        HStack {
                            Text(chat.type == .individual ? "Block User" : "Leave Chat")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                    }
                    
                    Divider().padding(.leading)
                    
                    Button(action: {}) {
                        HStack {
                            Text("Report")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            }
        }
        .background(Color.clear)
    } 

    private func profileRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(title)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    let session = AppSession()
    NavigationStack {
        ChatInfoView(chat: session.chatStore.chats[0])
            .environment(session)
    }
}
