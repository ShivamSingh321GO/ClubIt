//
//  ForgotPasswordSheet.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct ForgotPasswordSheet: View {
    @Binding var email: String
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss

    @State private var resetEmail: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert: Bool = false

    private var isEmailValid: Bool {
        let trimmed = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.contains("@") && trimmed.contains(".")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon & Title Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: "envelope.badge.shield.halffilled")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }

                    Text("Reset Password")
                        .font(.title2.weight(.bold))

                    Text("Enter your registered email address below and we will send you a password reset link.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 16)

                // Error Banner
                if let errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Email Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .foregroundStyle(.secondary)

                        TextField("Enter your email", text: $resetEmail)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }

                Spacer()

                // Action Button
                Button {
                    sendResetEmail()
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(isEmailValid ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isEmailValid || isLoading)
                .padding(.bottom, 16)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Link Sent", isPresented: $showSuccessAlert) {
                Button("OK") {
                    email = resetEmail
                    dismiss()
                }
            } message: {
                Text("We have sent a password reset link to \(resetEmail). Please check your email inbox to reset your password.")
            }
            .onAppear {
                if resetEmail.isEmpty {
                    resetEmail = email
                }
            }
        }
    }

    private func sendResetEmail() {
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await appSession.sendPasswordResetEmail(email: trimmedEmail)
                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordSheet(email: .constant("user@example.com"))
        .environment(AppSession())
}
