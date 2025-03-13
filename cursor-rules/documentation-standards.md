# Swift Documentation Standards for Cursor IDE

## General Documentation Guidelines

* Document all public APIs
* Write documentation in clear, concise English
* Update documentation when code changes
* Use Swift's built-in documentation comments (`///`)

## Method and Function Documentation

* Describe what the function does, not how it does it
* Document parameters, return values, and thrown errors
* Mention any side effects or important implementation details
* Include code examples for complex functionality

```swift
/// Fetches user data from the remote server.
///
/// This method connects to the user service API and retrieves the current user profile.
/// It should be called after the user has successfully authenticated.
///
/// ```swift
/// do {
///     let user = try await userService.fetchCurrentUser()
///     updateUI(with: user)
/// } catch {
///     handleError(error)
/// }
/// ```
///
/// - Parameters:
///   - forceRefresh: If `true`, ignores any cached data and fetches from the network
///   - completion: A closure called when the operation completes
/// - Returns: A `User` object containing the user's profile information
/// - Throws: `NetworkError.connectionFailed` if unable to reach the server
///           `NetworkError.unauthorized` if the user's session has expired
func fetchCurrentUser(forceRefresh: Bool = false) async throws -> User {
    // Implementation
}
```

## Type Documentation

* Document the purpose and responsibility of each type
* Explain the relationship with other types
* Mention any protocols conformances and their significance
* Include usage examples for complex types

```swift
/// A service responsible for managing user authentication and profile information.
///
/// `UserService` handles all communication with the authentication backend,
/// manages the user session, and provides access to user profile data.
///
/// Example:
/// ```swift
/// let service = UserService(apiClient: APIClient.shared)
/// try await service.login(username: "user", password: "pass")
/// let profile = try await service.fetchProfile()
/// ```
public class UserService {
    // Implementation
}
```

## Property Documentation

* Document the purpose and meaning of the property
* Mention any side effects of setting the property
* Include value ranges or constraints where applicable

```swift
/// The maximum number of login attempts before the account is temporarily locked.
///
/// This value cannot be less than 1 or greater than 10.
/// Default value is 5.
public var maxLoginAttempts: Int {
    didSet {
        maxLoginAttempts = min(10, max(1, maxLoginAttempts))
    }
}
```

## Extension Documentation

* Document why the extension exists and what functionality it adds
* Clarify what problem it solves
* Group related extension methods together

```swift
/// Extends `String` to provide user input validation capabilities.
///
/// These methods provide common validation patterns for user-provided strings
/// like emails, passwords, and usernames.
extension String {
    /// Checks if the string is a valid email address.
    ///
    /// - Returns: `true` if the string matches email pattern, `false` otherwise.
    func isValidEmail() -> Bool {
        // Implementation
    }
    
    /// Checks if the string meets password strength requirements.
    ///
    /// - Returns: `true` if the password is strong enough, `false` otherwise.
    func isStrongPassword() -> Bool {
        // Implementation
    }
}
```

## Documentation Organizations with MARK

* Use `// MARK: -` comments to organize code into logical sections
* Group related properties and methods together
* Add clear separation between implementation sections

```swift
class ProfileViewController: UIViewController {
    // MARK: - Properties
    private let user: User
    private let profileService: ProfileService
    
    // MARK: - UI Elements
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    
    // MARK: - Initialization
    init(user: User, profileService: ProfileService) {
        self.user = user
        self.profileService = profileService
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        // UI setup code
    }
    
    private func loadUserData() {
        // Data loading code
    }
}
```

## Project-Level Documentation

* Maintain a README.md file with project overview
* Document architecture and design patterns used
* Include setup instructions and requirements
* Keep architectural diagrams up to date

```markdown
# MyApp

## Overview
MyApp is an iOS application that helps users track their daily activities and fitness goals.

## Architecture
The app follows the MVVM architecture with Coordinators for navigation flow.

## Requirements
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Setup Instructions
1. Clone the repository
2. Run `pod install` to install dependencies
3. Open `MyApp.xcworkspace` in Xcode
4. Build and run the app
``` 