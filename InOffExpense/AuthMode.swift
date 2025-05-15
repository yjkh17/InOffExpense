import SwiftUI
import SwiftData

enum AuthMode: String, CaseIterable, Identifiable {
    case signIn = "Sign In"
    case createAccount = "Create Account"
    
    var id: String { self.rawValue }
}

struct ManualSignInView: View {
    @Environment(\.modelContext) private var modelContext
    // Persist login state using AppStorage.
    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    // Fetch all users for testing.
    @Query private var allUsers: [User]
    
    @State private var authMode: AuthMode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var formError: String?  // Renamed from 'error'
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Text("Welcome to In Off Expense")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Toggle between Sign In and Create Account
                Picker("Authentication Mode", selection: $authMode) {
                    ForEach(AuthMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Email Field
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Confirm Password Field (only in Create Account mode)
                if authMode == .createAccount {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Display error message if any
                if let formError = formError {
                    Text(formError)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Button: Sign In or Create Account
                Button(action: {
                    if authMode == .signIn {
                        signIn()
                    } else {
                        createAccount()
                    }
                }) {
                    Text(authMode == .signIn ? "Sign In" : "Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle(authMode == .signIn ? "Sign In" : "Create Account")
        }
    }
    
    // MARK: - Authentication Functions
    
    private func signIn() {
        let request = FetchDescriptor<User>(predicate: #Predicate { user in
            user.email == email && user.password == password
        })
        do {
            let users = try modelContext.fetch(request)
            if let user = users.first {
                storedEmail = user.email
                isLoggedIn = true
            } else {
                formError = "Invalid email or password."
            }
        } catch {
            formError = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    private func createAccount() {
        // Validate inputs.
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            formError = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            formError = "Passwords do not match."
            return
        }
        // Check if an account with this email already exists.
        let request = FetchDescriptor<User>(predicate: #Predicate { user in
            user.email == email
        })
        do {
            let existingUsers = try modelContext.fetch(request)
            if !existingUsers.isEmpty {
                formError = "An account with this email already exists."
                return
            }
        } catch {
            formError = "Failed to verify account: \(error.localizedDescription)"
            return
        }
        
        // Create and insert the new user.
        let newUser = User(email: email, password: password)
        modelContext.insert(newUser)
        do {
            try modelContext.save()
            storedEmail = newUser.email
            isLoggedIn = true
        } catch {
            formError = "Failed to create account: \(error.localizedDescription)"
        }
    }
}

struct ManualSignInView_Previews: PreviewProvider {
    static var container: ModelContainer = {
        let container = try! ModelContainer(for: Schema([User.self]))
        return container
    }()
    
    static var previews: some View {
        ManualSignInView()
            .modelContainer(container)
    }
}
