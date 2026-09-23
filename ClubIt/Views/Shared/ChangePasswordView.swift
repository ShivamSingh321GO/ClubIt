//
//  ChangePasswordView.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct ChangePasswordView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss

    // Step 1 State: Current Password
    @State private var currentPassword: String = ""
    @State private var isCurrentPasswordVisible: Bool = false
    @State private var isCurrentPasswordVerified: Bool = false
    @State private var isVerifyingCurrentPassword: Bool = false

    // Step 2 State: New Password & Confirm Password
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var isUpdatingPassword: Bool = false

    // Alerts & Messages
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert: Bool = false

    // Focus state
    @FocusState private var focusedField: Field?

    private enum Field {
        case currentPassword
        case newPassword
        case confirmPassword
    }

    // Validation rules
    private var isNewPasswordValidLength: Bool {
        newPassword.count >= 6
    }

    private var doPasswordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var isNewPasswordDifferent: Bool {
        newPassword != currentPassword
    }

    private var canSubmitNewPassword: Bool {
        isCurrentPasswordVerified && isNewPasswordValidLength && doPasswordsMatch && isNewPasswordDifferent && !isUpdatingPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                headerSection

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

                // STEP 1: Verify Existing Password
                step1Section

                // STEP 2: New Password Options (Revealed only after Step 1 verification)
                if isCurrentPasswordVerified {
                    step2Section
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password Updated", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been changed successfully. Please use your new password next time you log in.")
        }
        .onAppear {
            focusedField = .currentPassword
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: isCurrentPasswordVerified ? "lock.shield.fill" : "lock.rotation")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Text(isCurrentPasswordVerified ? "Create New Password" : "Verify Current Password")
                .font(.title3.weight(.bold))

            Text(isCurrentPasswordVerified
                 ? "Enter your new password below. Make sure it is at least 6 characters long."
                 : "To change your password, please enter your existing password first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Step 1: Existing Password Section
    private var step1Section: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("STEP 1: EXISTING PASSWORD")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                if isCurrentPasswordVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Verified")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if isCurrentPasswordVisible {
                        TextField("Enter existing password", text: $currentPassword)
                            .disabled(isCurrentPasswordVerified)
                    } else {
                        SecureField("Enter existing password", text: $currentPassword)
                            .disabled(isCurrentPasswordVerified)
                    }

                    Button {
                        isCurrentPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isCurrentPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .focused($focusedField, equals: .currentPassword)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCurrentPasswordVerified ? Color.green : Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }

            if !isCurrentPasswordVerified {
                Button {
                    verifyCurrentPassword()
                } label: {
                    HStack {
                        Spacer()
                        if isVerifyingCurrentPassword {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Verify Password")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(currentPassword.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(currentPassword.isEmpty || isVerifyingCurrentPassword)
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Step 2: New Password Options Section
    private var step2Section: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STEP 2: NEW PASSWORD")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

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
                .focused($focusedField, equals: .newPassword)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }

            // Confirm New Password Field
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
                .focused($focusedField, equals: .confirmPassword)
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
                validationRow(
                    isSatisfied: isNewPasswordValidLength,
                    text: "At least 6 characters long"
                )
                validationRow(
                    isSatisfied: doPasswordsMatch,
                    text: "Passwords match"
                )
                validationRow(
                    isSatisfied: isNewPasswordDifferent,
                    text: "Different from current password"
                )
            }
            .padding(.top, 4)

            // Submit Button
            Button {
                updatePassword()
            } label: {
                HStack {
                    Spacer()
                    if isUpdatingPassword {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Confirm New Password")
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(canSubmitNewPassword ? Color.accentColor : Color.gray.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSubmitNewPassword)
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

    // MARK: - Actions

    private func verifyCurrentPassword() {
        errorMessage = nil
        isVerifyingCurrentPassword = true

        Task {
            do {
                _ = try await appSession.verifyCurrentPassword(currentPassword)
                await MainActor.run {
                    isVerifyingCurrentPassword = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isCurrentPasswordVerified = true
                    }
                    focusedField = .newPassword
                }
            } catch {
                await MainActor.run {
                    isVerifyingCurrentPassword = false
                    errorMessage = "Incorrect existing password. Please check and try again."
                }
            }
        }
    }

    private func updatePassword() {
        guard canSubmitNewPassword else { return }

        errorMessage = nil
        isUpdatingPassword = true

        Task {
            do {
                try await appSession.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                await MainActor.run {
                    isUpdatingPassword = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isUpdatingPassword = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environment(AppSession())
    }
}
