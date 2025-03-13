# Swift Style Guide for Cursor IDE

## Naming Conventions

* Use camelCase for variable and function names
* Use PascalCase for type names (classes, structs, enums)
* Use descriptive names that clearly communicate purpose
* Avoid abbreviations except for commonly understood ones

```swift
// Preferred
let userAccountID = 123
func fetchUserData() { }
class NetworkManager { }

// Avoid
let uid = 123
func getData() { }
class NM { }
```

## Code Formatting

* Use 4 spaces for indentation (not tabs)
* Keep line length to a maximum of 100 characters
* Add a single space after control flow keywords (`if`, `for`, `while`, etc.)
* Use new lines to separate logical sections of code

```swift
// Preferred
if condition {
    performAction()
}

// Avoid
if(condition){performAction()}
```

## Type Safety

* Prefer Swift's strong type system over loose types
* Avoid force unwrapping optionals with `!`
* Use optional binding (`if let`, `guard let`) or nil coalescing (`??`)
* Use type inference only when the type is obvious

```swift
// Preferred
guard let user = user else { return }
let value = optionalValue ?? defaultValue

// Avoid
let user = getUser()!
```

## Access Control

* Explicitly declare access control for types and methods
* Use the most restrictive access level that suffices
* Prefer `private` and `fileprivate` for implementation details

```swift
public class MyService {
    private let apiClient: APIClient
    
    public func fetchData() -> Data {
        // Implementation
    }
    
    private func processResponse(_ response: Response) {
        // Implementation
    }
}
```

## Protocol Conformance

* Group protocol conformance in extensions
* Keep the main type declaration clean and focused
* Add MARK comments for clarity

```swift
// Main class definition
class MyViewController: UIViewController {
    // Core functionality
}

// MARK: - UITableViewDelegate
extension MyViewController: UITableViewDelegate {
    // Table view delegate methods
}

// MARK: - UITableViewDataSource
extension MyViewController: UITableViewDataSource {
    // Table view data source methods
}
```

## Commenting

* Use comments to explain "why" not "what"
* Use Swift's built-in documentation comments (`///`) for public APIs
* Keep comments up to date with code changes

```swift
/// Fetches user data from the remote API
/// - Parameter userID: The unique identifier of the user
/// - Returns: A User object if successful
/// - Throws: NetworkError if the request fails
func fetchUser(userID: String) throws -> User {
    // Implementation
}
``` 