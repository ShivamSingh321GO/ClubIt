//
//  MockAuthService.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import Foundation

struct MockAuthService {

    struct LoginResult {
        let user: User
        let role: AppRole
    }

    func signIn(email: String, password: String) throws -> LoginResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        guard let user = MockData.allMockUsers.first(where: { 
            $0.email.lowercased() == trimmedEmail
        }) else {
            throw AuthError.invalidCredentials
        }

        return LoginResult(user: user, role: user.role)
    }

    private func mockName(for role: AppRole) -> String {
        switch role {
        case .admin: return "Admin User"
        case .faculty: return "Faculty Advisor"
        case .president: return "President"
        case .vicePresident: return "Vice President"
        case .clubLead: return "Club Lead"
        case .clubMember: return "Club Member"
        case .student: return "Student"
        }
    }
}

enum AuthError: LocalizedError {
    case emptyFields
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please enter both email and password."
        case .invalidCredentials:
            return "Invalid email or password."
        }
    }
}
