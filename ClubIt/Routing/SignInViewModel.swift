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

    private let authService = MockAuthService()

    func signIn(appSession: AppSession) {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        isLoading = true

        do {
            let result = try authService.signIn(email: trimmedEmail, password: trimmedPassword)
            appSession.signIn(user: result.user, role: result.role)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}