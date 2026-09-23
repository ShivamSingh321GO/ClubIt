//
//  ResetPasswordView.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct ResetPasswordView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert: Bool = false

    private var isPasswordValidLength: Bool {
        newPassword.count >= 6
    }

    private var doPasswordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var canSubmit: Bool {
        isPasswordValidLength && doPasswordsMatch && !isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 72, height: 72)

                            Image(systemName: "lock.shield")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text("Set New Password")
                            .font(.title2.weight(.bold))

                        Text("Your recovery link was verified. Please enter your new password below.")
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

                    // Form Fields
                    VStack(alignment: .leading, spacing: 16) {
                        // New Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                if isNewPasswordVisible {
                                    TextField("Enter new password", text: $newPassword)
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                }

                                Button {
                                    isNewPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                if isConfirmPasswordVisible {
                                    TextField("Re-enter new password", text: $confirmPassword)
                                } else {
                                    SecureField("Re-enter new password", text: $confirmPassword)
                                }

                                Button {
                                    isConfirmPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Validation Checklist
                        VStack(alignment: .leading, spacing: 8) {
                            validationRow(isSatisfied: isPasswordValidLength, text: "At least 6 characters long")
                            validationRow(isSatisfied: doPasswordsMatch, text: "Passwords match")
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Submit Button
                    Button {
                        submitNewPassword()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Update Password")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canSubmit)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New Password")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Password Updated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    appSession.isPasswordResetMode = false
                    dismiss()
                }
            } message: {
                Text("Your password has been successfully updated. You can now log in with your new password.")
            }
        }
    }

    private func validationRow(isSatisfied: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isSatisfied ? "checkmark.circle.fill" : "circle")
                .font(.subheadline)
                .foregroundStyle(isSatisfied ? .green : .secondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(isSatisfied ? .primary : .secondary)
        }
    }

    private func submitNewPassword() {
        guard canSubmit else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await appSession.completePasswordReset(newPassword: newPassword)
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
    ResetPasswordView()
        .environment(AppSession())
}
