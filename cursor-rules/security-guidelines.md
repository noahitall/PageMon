# Swift Security Guidelines for Cursor IDE

## Data Storage

* Never store sensitive information in UserDefaults unencrypted
* Use Keychain for storing credentials, tokens, and other sensitive data
* Use file encryption for sensitive data stored in files
* Apply appropriate data protection classes

```swift
// Preferred - Using Keychain
import KeychainAccess

let keychain = Keychain(service: "com.yourapp.service")
keychain["accessToken"] = token

// Avoid - Using UserDefaults for sensitive data
UserDefaults.standard.set(token, forKey: "accessToken")
```

## Network Security

* Always use HTTPS/TLS for network communications
* Implement certificate pinning for critical APIs
* Validate server certificates
* Handle authentication tokens securely

```swift
// Configure proper TLS
let session = URLSession(configuration: .default)
var request = URLRequest(url: URL(string: "https://api.example.com")!)
request.httpMethod = "POST"

// Certificate pinning example
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, 
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Certificate validation logic
    }
}
```

## Input Validation

* Always validate and sanitize user input
* Use proper data types for parameters
* Check bounds and ranges for numeric values
* Validate URL and file paths

```swift
// Validate user input
guard let age = Int(ageString), age >= 18, age <= 120 else {
    throw ValidationError.invalidAge
}

// URL validation
guard let url = URL(string: userProvidedString), 
      url.scheme == "https",
      url.host?.contains("trusted-domain.com") == true else {
    throw ValidationError.invalidURL
}
```

## Secure Coding

* Avoid hardcoding sensitive information like API keys
* Use environment variables or secure storage
* Implement proper error handling that doesn't leak sensitive information
* Use memory-secure practices for sensitive data

```swift
// Avoid
let apiKey = "1234-abcd-5678-efgh"

// Preferred
func getAPIKey() throws -> String {
    // Retrieve from secure storage
}

// Secure memory handling
func processCredentials(username: String, password: String) {
    defer {
        // Clear sensitive data when function exits
        memset_s(UnsafeMutableRawPointer(mutating: password), password.count, 0, password.count)
    }
    // Process credentials
}
```

## Access Control

* Use App Transport Security (ATS) properly
* Implement proper permission handling
* Use the principle of least privilege
* Implement proper authentication checks

```swift
// Request only necessary permissions
import Photos

PHPhotoLibrary.requestAuthorization { status in
    switch status {
    case .authorized:
        // Access photos
    case .denied, .restricted:
        // Handle lack of access
    case .notDetermined:
        // Handle not determined state
    @unknown default:
        // Handle future cases
    }
}
```

## Cryptography Best Practices

* Use Apple's CryptoKit for cryptographic operations
* Avoid implementing your own cryptographic algorithms
* Use strong encryption methods and key sizes
* Implement secure key management

```swift
import CryptoKit

// Secure hashing
func hashPassword(_ password: String) -> String {
    let inputData = Data(password.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

// Encryption with CryptoKit
func encryptData(_ data: Data, with key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined!
}
``` 