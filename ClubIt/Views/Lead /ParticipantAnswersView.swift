import SwiftUI

struct ParticipantAnswersView: View {
    let user: User
    let registration: IndividualRegistration
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header info
                    VStack(spacing: 8) {
                        UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 80)
                        
                        Text(user.name)
                            .font(.title2.bold())
                        
                        Text("\(user.course ?? "N/A") • \(user.year ?? "N/A")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    if let answers = registration.answers, !answers.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Registration Answers")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                            
                            VStack(spacing: 0) {
                                let sortedAnswers = Array(answers).sorted(by: { $0.key < $1.key })
                                ForEach(Array(sortedAnswers.enumerated()), id: \.element.key) { index, pair in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(pair.key)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(pair.value)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if index < answers.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "text.document")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary.opacity(0.5))
                            
                            Text("No answers provided")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Registration Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//#Preview {
//    ParticipantAnswersView(
//        user: MockData.sampleUser,
//        registration: IndividualRegistration(
//            id: UUID(),
//            eventId: UUID(),
//            userId: MockData.sampleUser.id,
//            status: .confirmed,
//            answers: ["Why do you want to join?": "I'm very interested in technology and would love to contribute.", "Experience Level": "Intermediate"],
//            createdAt: Date()
//        )
//    )
//}
