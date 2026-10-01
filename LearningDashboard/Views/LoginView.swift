//
//  LoginView.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var viewModel = LoginViewModel()
    @State private var showDashboard = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Spacer()

                VStack(spacing: 8) {
                    Text("Learning Dashboard")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue learning")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {

                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        if await viewModel.login() {
                            showDashboard = true
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding(24)
            .navigationDestination(isPresented: $showDashboard) {
                CourseDashboardView()
            }
        }
    }
}

#Preview {
    LoginView()
}
