# SwiftUI Best Practices for Cursor IDE

## View Structure and Organization

* Keep view components small and focused on a single responsibility
* Extract reusable view components into separate structures
* Use view extensions to organize functionality
* Place preview providers at the bottom of the file

```swift
// Main view with focused responsibility
struct UserProfileView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            profileHeader
            statsSection
            aboutSection
            actionButtons
        }
        .padding()
    }
}

// Extensions for organization
extension UserProfileView {
    private var profileHeader: some View {
        HStack {
            CircleImageView(url: user.avatarURL)
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.title)
                Text(user.handle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var statsSection: some View {
        // Stats implementation
        HStack {
            StatView(value: user.followers, label: "Followers")
            Divider()
            StatView(value: user.following, label: "Following")
        }
    }
    
    // Additional sections...
}

// Reusable component
struct CircleImageView: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 60, height: 60)
        .clipShape(Circle())
    }
}

// Preview at the bottom
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User.previewUser)
    }
}
```

## State Management

* Use appropriate property wrappers for state: `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
* Keep state at the appropriate level in the view hierarchy
* Pass only the state that views need, not entire models
* Consider using state containers for complex applications

```swift
// State container
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadProfile(for userID: String) {
        isLoading = true
        errorMessage = nil
        
        // Loading implementation...
    }
}

// View using the state
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    let userID: String
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let profile = viewModel.profile {
                ProfileContentView(profile: profile)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            }
        }
        .onAppear {
            viewModel.loadProfile(for: userID)
        }
    }
}
```

## Performance Optimization

* Use lazy loading for lists and grids with many items
* Apply `@ViewBuilder` for conditional view construction
* Leverage `equatable` to prevent unnecessary view updates
* Use `LazyVStack` and `LazyHStack` for large collections

```swift
struct ContentFeedView: View {
    let posts: [Post]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(posts) { post in
                    PostView(post: post)
                        .equatable() // Only redraw if post changes
                }
            }
            .padding()
        }
    }
}

// Make PostView equatable to improve performance
struct PostView: View, Equatable {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title)
                .font(.headline)
            Text(post.content)
                .font(.body)
        }
    }
    
    // Only redraw if post content changes
    static func == (lhs: PostView, rhs: PostView) -> Bool {
        lhs.post.id == rhs.post.id &&
        lhs.post.title == rhs.post.title &&
        lhs.post.content == rhs.post.content
    }
}
```

## Navigation and Routing

* Use SwiftUI's navigation APIs consistently
* Consider implementing a coordinator pattern for complex navigation
* Use programmatic navigation for dynamic flows
* Prefer `.navigationDestination` over deprecated navigation methods

```swift
// Modern navigation approach
struct AppContentView: View {
    @StateObject private var router = AppRouter()
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            ContentListView()
                .navigationDestination(for: ContentID.self) { contentID in
                    ContentDetailView(id: contentID)
                }
                .navigationDestination(for: UserID.self) { userID in
                    UserProfileView(id: userID)
                }
        }
        .environmentObject(router)
    }
}

// Router to manage navigation state
class AppRouter: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    func navigateToContent(_ id: ContentID) {
        navigationPath.append(id)
    }
    
    func navigateToProfile(_ id: UserID) {
        navigationPath.append(id)
    }
    
    func navigateBack() {
        navigationPath.removeLast()
    }
    
    func navigateToRoot() {
        navigationPath = NavigationPath()
    }
}
```

## Accessibility

* Add meaningful accessibility labels and hints
* Support dynamic type sizes
* Implement proper keyboard navigation
* Test with VoiceOver and accessibility inspector

```swift
Button(action: {
    viewModel.refreshContent()
}) {
    Image(systemName: "arrow.clockwise")
        .imageScale(.large)
}
.accessibilityLabel("Refresh content")
.accessibilityHint("Double tap to refresh the current content")

// Support dynamic type
Text("Welcome")
    .font(.title)
    .dynamicTypeSize(.xSmall...5xlarge)
    
// Keyboard navigation
TextField("Username", text: $username)
    .submitLabel(.next)
    .onSubmit {
        focusedField = .password
    }
```

## Design System Integration

* Create a consistent design system with reusable components
* Use style extensions for consistent appearance
* Create custom view modifiers for common styling patterns
* Centralize color and font definitions

```swift
// Define app colors
extension Color {
    static let appPrimary = Color("PrimaryColor")
    static let appSecondary = Color("SecondaryColor")
    static let appBackground = Color("BackgroundColor")
}

// Custom view modifier
struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.appPrimary)
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(radius: 2)
    }
}

// Extension for easy application
extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
}

// Usage
Button("Sign In") {
    // Action
}
.primaryButtonStyle()
``` 