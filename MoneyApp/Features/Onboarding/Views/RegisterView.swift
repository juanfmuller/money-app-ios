//
//  RegisterView.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var viewModel = RegisterViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)
                    
                    // Header
                    headerSection
                    
                    // Registration Form
                    registrationForm
                    
                    // Terms & Conditions
                    termsSection
                    
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
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Join Money App to start managing your finances smarter.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var registrationForm: some View {
        VStack(spacing: 16) {
            // Name Fields
            HStack(spacing: 12) {
                // First Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("First Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("First name", text: $viewModel.firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.firstName) { _, _ in
                            viewModel.validateField("firstName")
                        }
                    
                    if let error = viewModel.firstNameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Last Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Last name", text: $viewModel.lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.lastName) { _, _ in
                            viewModel.validateField("lastName")
                        }
                    
                    if let error = viewModel.lastNameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.email) { _, _ in
                        viewModel.validateField("email")
                    }
                
                if let error = viewModel.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                SecureField("Create a password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.password) { _, _ in
                        viewModel.validateField("password")
                    }
                
                if let error = viewModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Must contain letters, numbers, and special characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm Password")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                SecureField("Confirm your password", text: $viewModel.confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.confirmPassword) { _, _ in
                        viewModel.validateField("confirmPassword")
                    }
                
                if let error = viewModel.confirmPasswordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                viewModel.acceptedTerms.toggle()
            }) {
                Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(viewModel.acceptedTerms ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Button("Terms of Service") {
                        // TODO: Show terms of service
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Privacy Policy") {
                        // TODO: Show privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Create Account Button
            Button(action: {
                Task { await viewModel.register() }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading || !isFormValid)
            
            // Sign In Instead
            Button(action: {
                viewModel.navigateToLogin()
            }) {
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !viewModel.firstName.isEmpty &&
        !viewModel.lastName.isEmpty &&
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        !viewModel.confirmPassword.isEmpty &&
        viewModel.acceptedTerms &&
        viewModel.emailError == nil &&
        viewModel.passwordError == nil &&
        viewModel.confirmPasswordError == nil &&
        viewModel.firstNameError == nil &&
        viewModel.lastNameError == nil
    }
}

// MARK: - Preview

#Preview {
    RegisterView()
        .environmentObject(AppRouter())
}