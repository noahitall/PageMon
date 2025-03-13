# Swift Testing Guidelines for Cursor IDE

## Unit Testing Best Practices

* Write tests that are independent and can run in any order
* Follow the AAA pattern: Arrange, Act, Assert
* Test one concept per test method
* Use descriptive test method names that explain what is being tested

```swift
import XCTest
@testable import MyApp

class UserServiceTests: XCTestCase {
    // Arrange: Setup common test objects
    var sut: UserService!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = UserService(apiClient: mockAPIClient)
    }
    
    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }
    
    // Good: Clear test name and single concept being tested
    func testAuthenticateUser_WithValidCredentials_ReturnsUser() {
        // Arrange
        let expectedUser = User(id: "123", name: "Test User")
        mockAPIClient.mockResponse = .success(expectedUser)
        
        // Act
        var resultUser: User?
        var resultError: Error?
        
        let expectation = expectation(description: "Authenticate completes")
        sut.authenticate(username: "testuser", password: "password") { result in
            switch result {
            case .success(let user):
                resultUser = user
            case .failure(let error):
                resultError = error
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Assert
        XCTAssertNil(resultError)
        XCTAssertEqual(resultUser?.id, expectedUser.id)
        XCTAssertEqual(resultUser?.name, expectedUser.name)
    }
}
```

## Mocking and Dependency Injection

* Use dependency injection to make code testable
* Create mock implementations of dependencies for testing
* Use protocols to define interfaces that can be mocked
* Limit mocking to dependencies outside of the system under test

```swift
// Protocol that can be implemented by real and mock versions
protocol APIClientProtocol {
    func request<T: Decodable>(endpoint: String, completion: @escaping (Result<T, Error>) -> Void)
}

// Real implementation for production
class APIClient: APIClientProtocol {
    func request<T: Decodable>(endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        // Real implementation that makes network requests
    }
}

// Mock implementation for testing
class MockAPIClient: APIClientProtocol {
    var mockResponse: Result<Any, Error>?
    
    func request<T: Decodable>(endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let mockResponse = mockResponse else {
            fatalError("Mock response not set")
        }
        
        switch mockResponse {
        case .success(let value):
            if let typedValue = value as? T {
                completion(.success(typedValue))
            } else {
                completion(.failure(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Type mismatch"])))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

## Test Coverage

* Aim for high test coverage, but focus on critical paths
* Test edge cases and error conditions
* Use test coverage tools to identify untested code
* Don't chase 100% coverage at the expense of meaningful tests

```swift
func testUserAuthentication_WithInvalidCredentials_ReturnsAuthenticationError() {
    // Arrange
    let expectedError = AuthenticationError.invalidCredentials
    mockAPIClient.mockResponse = .failure(expectedError)
    
    // Act
    var resultUser: User?
    var resultError: Error?
    
    let expectation = expectation(description: "Authentication fails")
    sut.authenticate(username: "wronguser", password: "wrongpassword") { result in
        switch result {
        case .success(let user):
            resultUser = user
        case .failure(let error):
            resultError = error
        }
        expectation.fulfill()
    }
    
    waitForExpectations(timeout: 1.0)
    
    // Assert
    XCTAssertNil(resultUser)
    XCTAssertNotNil(resultError)
    XCTAssertTrue(resultError is AuthenticationError)
    if let authError = resultError as? AuthenticationError {
        XCTAssertEqual(authError, .invalidCredentials)
    }
}
```

## UI Testing

* Focus on critical user flows and interactions
* Use accessibility identifiers to identify UI elements
* Keep UI tests separate from unit tests
* Make UI tests as robust as possible against minor UI changes

```swift
import XCTest

class LoginScreenUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    func testLoginScreen_SuccessfulLogin_NavigatesToDashboard() {
        // Navigate to login screen if needed
        app.buttons["loginButton"].tap()
        
        // Enter credentials
        let usernameField = app.textFields["usernameField"]
        let passwordField = app.secureTextFields["passwordField"]
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("password")
        
        app.buttons["submitButton"].tap()
        
        // Assert that we're on the dashboard
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
    }
}
```

## Test-Driven Development (TDD)

* Consider writing tests before implementing features
* Follow the Red-Green-Refactor cycle
* Use TDD for complex logic and algorithms
* Write failing tests, then implement code to make them pass

```swift
// TDD Example:
// 1. First, write a failing test
func testCalculateDiscount_StandardDiscount_Returns10Percent() {
    // Arrange
    let sut = PriceCalculator()
    let originalPrice = Decimal(100.0)
    
    // Act
    let discountedPrice = sut.calculateDiscount(for: originalPrice, discountType: .standard)
    
    // Assert
    XCTAssertEqual(discountedPrice, Decimal(90.0))
}

// 2. Then implement the code to make it pass
class PriceCalculator {
    enum DiscountType {
        case none
        case standard
        case premium
    }
    
    func calculateDiscount(for price: Decimal, discountType: DiscountType) -> Decimal {
        switch discountType {
        case .none:
            return price
        case .standard:
            return price * Decimal(0.9)  // 10% discount
        case .premium:
            return price * Decimal(0.8)  // 20% discount
        }
    }
}
```

## Performance Testing

* Write tests that measure performance critical code
* Set baselines for performance and test against them
* Use XCTest's performance testing APIs
* Run performance tests on representative devices

```swift
func testPerformance_SortingLargeArray() {
    // Arrange
    var largeArray = (0..<10000).map { _ in Int.random(in: 0..<10000) }
    
    // Act & Assert performance
    measure {
        // This code will be measured for performance
        largeArray.sort()
    }
}
``` 