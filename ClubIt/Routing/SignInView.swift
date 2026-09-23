import SwiftUI
import ClubItShared

struct SignInView: View {
    
    @State private var viewModel = SignInViewModel()
    @Environment(AppSession.self) private var appSession
    
    @State private var showingForgotPasswordSheet = false
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email
        case password
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Email") {
                    TextField("Enter Your Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                
                Section {
                    HStack {
                        Group {
                            if viewModel.isPasswordVisible {
                                TextField("Enter Password", text: $viewModel.password)
                            } else {
                                SecureField("Enter Password", text: $viewModel.password)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            focusedField = nil
                            Task {
                                await viewModel.signIn(appSession: appSession)
                            }
                        }
                        
                        Button {
                            viewModel.isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.accentColor)
                        }
                    }
                } header: {
                    Text("Password")
                } footer: {
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showingForgotPasswordSheet = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                }
                
                Toggle("Remember me", isOn: $viewModel.rememberMe)
                    .tint(.accentColor)
                    .listRowBackground(Color.clear)
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        focusedField = nil
                        Task {
                            await viewModel.signIn(appSession: appSession)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Login")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .listRowBackground(Color.accentColor)
                }
                
//                Text("OR")
                
                
            }
            .navigationTitle("Sign in")
            .sheet(isPresented: $showingForgotPasswordSheet) {
                ForgotPasswordSheet(email: $viewModel.email)
            }
            
//            Button {
//                // Guest Action
//            } label: {
//                Text("Continue as a Guest")
//                    .frame(maxWidth: .infinity)
//                    .foregroundColor(.accentColor)
//            }
//            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    SignInView()
        .environment(AppSession())
}
