import SwiftUI
import ClubItShared
import PhotosUI

struct EditSubgroupDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var name: String
    @State private var tagLine: String
    @State private var description: String
    @State private var category: SubgroupCategory
    @State private var memberCount: Int
    @State private var eventCount: Int
    @State private var instagram: String
    @State private var facebook: String
    @State private var linkedin: String
    @State private var whatsapp: String
    @State private var discord: String
    @State private var logo: String
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    
    init(subgroup: Subgroup) {
        _name = State(initialValue: subgroup.name)
        _tagLine = State(initialValue: subgroup.tagLine ?? "")
        _description = State(initialValue: subgroup.description ?? "")
        _category = State(initialValue: subgroup.category)
        _memberCount = State(initialValue: subgroup.memberCount ?? 0)
        _eventCount = State(initialValue: subgroup.eventCount ?? 0)
        _instagram = State(initialValue: (subgroup.socials ?? [:])["instagram"] ?? "")
        _facebook = State(initialValue: (subgroup.socials ?? [:])["facebook"] ?? "")
        _linkedin = State(initialValue: (subgroup.socials ?? [:])["linkedin"] ?? "")
        _whatsapp = State(initialValue: (subgroup.socials ?? [:])["whatsapp"] ?? "")
        _discord = State(initialValue: (subgroup.socials ?? [:])["discord"] ?? "")
        _logo = State(initialValue: subgroup.logo)
        _imageData = State(initialValue: subgroup.imageData)
    }
    
    var body: some View {
        Form {
            Section("Basic Information") {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 80, height: 80)
                            
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else if !logo.isEmpty && UIImage(named: logo) != nil {
                                Image(logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .padding(15)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .frame(width: 80, height: 80)
                        .overlay(alignment: .bottom) {
                            Text("Edit")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                        }
                        .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Subgroup Name", text: $name)
                            .font(.headline)
                        
                        Divider()
                        
                        TextField("Tagline", text: $tagLine)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
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
                        .frame(minHeight: 100)
                }
            }
            
            Section("Category") {
                Picker("Subgroup Category", selection: $category) {
                    ForEach(SubgroupCategory.allCases, id: \.self) { category in
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
        .navigationTitle("Edit Subgroup")
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
        
        Task {
            do {
                try await appSession.subgroupStore.updateSubgroup(
                    name: name,
                    tagLine: tagLine,
                    description: description,
                    category: category,
                    memberCount: memberCount,
                    eventCount: eventCount,
                    socials: updatedSocials,
                    logo: logo,
                    imageData: imageData
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("DEBUG ERROR: Failed to update subgroup: \(error)")
            }
        }
    }
}

#Preview {
    let session = AppSession()
    NavigationStack {
        EditSubgroupDetailView(subgroup: MockData.technoJamSubgroup)
            .environment(session)
    }
}
