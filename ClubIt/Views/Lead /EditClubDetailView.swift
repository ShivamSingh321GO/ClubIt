import SwiftUI

struct EditClubDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var name: String
    @State private var tagLine: String
    @State private var description: String
    @State private var category: ClubCategory
    @State private var memberCount: Int
    @State private var eventCount: Int
    @State private var instagram: String
    @State private var facebook: String
    @State private var linkedin: String
    @State private var whatsapp: String
    @State private var discord: String
    
    init(club: Club) {
        _name = State(initialValue: club.name)
        _tagLine = State(initialValue: club.tagLine)
        _description = State(initialValue: club.description)
        _category = State(initialValue: club.category)
        _memberCount = State(initialValue: club.memberCount)
        _eventCount = State(initialValue: club.eventCount)
        _instagram = State(initialValue: club.socials["instagram"] ?? "")
        _facebook = State(initialValue: club.socials["facebook"] ?? "")
        _linkedin = State(initialValue: club.socials["linkedin"] ?? "")
        _whatsapp = State(initialValue: club.socials["whatsapp"] ?? "")
        _discord = State(initialValue: club.socials["discord"] ?? "")
    }
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Club Name", text: $name)
                TextField("Tagline", text: $tagLine)
            }
            
            Section("Description") {
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Add description")
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $description)
                        .frame(minHeight: 150)
                }
            }
            
            Section("Category") {
                Picker("Club Category", selection: $category) {
                    ForEach(ClubCategory.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
            }
            
            Section("Social Links") {
                TextField("Instagram URL", text: $instagram)
                    .autocapitalization(.none)
                TextField("Facebook URL", text: $facebook)
                    .autocapitalization(.none)
                TextField("LinkedIn URL", text: $linkedin)
                    .autocapitalization(.none)
                TextField("WhatsApp URL", text: $whatsapp)
                    .autocapitalization(.none)
                TextField("Discord URL", text: $discord)
                    .autocapitalization(.none)
            }
        }
        .navigationTitle("Edit Club")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "xmark")
//                }
//            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveChanges()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func saveChanges() {
        var updatedSocials: [String: String] = [:]
        if !instagram.isEmpty { updatedSocials["instagram"] = instagram }
        if !facebook.isEmpty { updatedSocials["facebook"] = facebook }
        if !linkedin.isEmpty { updatedSocials["linkedin"] = linkedin }
        if !whatsapp.isEmpty { updatedSocials["whatsapp"] = whatsapp }
        if !discord.isEmpty { updatedSocials["discord"] = discord }
        
        appSession.clubStore.updateClub(
            name: name,
            tagLine: tagLine,
            description: description,
            category: category,
            memberCount: memberCount,
            eventCount: eventCount,
            socials: updatedSocials
        )
        dismiss()
    }
}

#Preview {
    let session = AppSession()
    NavigationStack {
        EditClubDetailView(club: MockData.technoJamClub)
            .environment(session)
    }
}
