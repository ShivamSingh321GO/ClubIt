import SwiftUI
import ClubItShared
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let user: User
    
    @State private var name: String
    @State private var bio: String
    @State private var phoneNumber: String
    @State private var course: String
    @State private var year: String
    @State private var admissionNumber: String
    @State private var imageData: Data?
    @State private var profileImg: String
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    init(user: User) {
        self.user = user
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
                    .onChange(of: phoneNumber) { _, newValue in
                        if newValue.count > 15 {
                            phoneNumber = String(newValue.prefix(15))
                        }
                    }
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
                Button {
                    saveProfile()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .bold()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .alert("Error Saving Profile", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Failed to save profile. Please check your network connection and try again.")
        }
    }
    
    private func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await appSession.updateUserProfile(
                    targetUser: user,
                    name: name,
                    bio: bio,
                    phoneNumber: phoneNumber,
                    course: course,
                    year: year,
                    admissionNumber: admissionNumber,
                    imageData: imageData
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(user: MockData.subgroupLeadUser)
            .environment(AppSession())
    }
}
