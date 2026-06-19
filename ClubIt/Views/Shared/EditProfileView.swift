import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var name: String
    @State private var bio: String
    @State private var phoneNumber: String
    @State private var course: String
    @State private var year: String
    @State private var admissionNumber: String
    @State private var imageData: Data?
    @State private var profileImg: String
    @State private var selectedItem: PhotosPickerItem?
    
    init(user: User) {
        _name = State(initialValue: user.name)
        _bio = State(initialValue: user.bio ?? "")
        _phoneNumber = State(initialValue: user.phoneNumber ?? "")
        _course = State(initialValue: user.course ?? "")
        _year = State(initialValue: user.year ?? "")
        _admissionNumber = State(initialValue: user.admissionNumber ?? "")
        _imageData = State(initialValue: user.imageData)
        _profileImg = State(initialValue: user.profileImg ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if !profileImg.isEmpty {
                                Image(profileImg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .foregroundStyle(.secondary)
                                    .clipShape(Circle())
                            }
                        }
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
                    Spacer()
                }
                .padding(.vertical, 8)
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            imageData = data
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
            
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Course", text: $course)
                TextField("Year", text: $year)
                TextField("Admission Number", text: $admissionNumber)
            }
            
            Section("Bio") {
                TextField("Write something about yourself...", text: $bio, axis: .vertical)
                    .lineLimit(4...10)
                    .frame(minHeight: 100, alignment: .topLeading)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        do {
                            try await appSession.updateUserProfile(
                                name: name,
                                bio: bio,
                                phoneNumber: phoneNumber,
                                course: course,
                                year: year,
                                admissionNumber: admissionNumber,
                                imageData: imageData
                            )
                            await MainActor.run {
                                dismiss()
                            }
                        } catch {
                            print("DEBUG ERROR: Failed to save profile: \(error.localizedDescription)")
                        }
                    }
                }
                .bold()
                .disabled(name.isEmpty)
            }
//            ToolbarItem(placement: .topBarLeading) {
//                Button("Cancel") {
//                    dismiss()
//                }
//            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(user: MockData.clubLeadUser)
            .environment(AppSession())
    }
}
