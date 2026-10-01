//
//  LoginViewModel.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email = ""
    @Published var password = ""

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func login() async -> Bool {
        guard !isLoading else {
            return false
        }

        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedEmail.isValidEmail else {
            errorMessage = "Please enter a valid email address."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must contain at least 6 characters."
            return false
        }

        isLoading = true

        // Mock authentication delay
        try? await Task.sleep(for: .milliseconds(700))

        isLoading = false

        return true
    }
}

private extension String {

    var isValidEmail: Bool {
        contains("@") && contains(".")
    }
}
