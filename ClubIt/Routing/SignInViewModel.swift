//
//  SignInViewModel.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import Foundation
import Observation

@Observable
final class SignInViewModel {
    var email: String = ""
    var password: String = ""
    var rememberMe: Bool = true
    var isPasswordVisible: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService = SupabaseAuthService()

    @MainActor
    func signIn(appSession: AppSession) async {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        isLoading = true

        do {
            let user = try await authService.signIn(email: trimmedEmail, password: trimmedPassword)
            await appSession.signIn(user: user, role: user.role)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}