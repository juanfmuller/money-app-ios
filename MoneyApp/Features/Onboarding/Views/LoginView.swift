//
//  LoginView.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // App Logo & Title
                    logoSection
                    
                    // Login Form
                    loginForm
                    
                    // Actions
                    actionButtons
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.router = router
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Money App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Welcome back! Sign in to continue.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                SecureField("Enter your password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Login Button
            Button(action: {
                Task { await viewModel.login() }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
            
            // Forgot Password
            Button(action: {
                viewModel.resetPassword()
            }) {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.vertical, 8)
            
            // Create Account Button
            Button(action: {
                viewModel.navigateToRegister()
            }) {
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AppRouter())
}