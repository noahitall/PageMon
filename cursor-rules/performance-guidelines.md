# Swift Performance Guidelines for Cursor IDE

## Memory Management

* Avoid retain cycles with proper use of `weak` and `unowned` references
* Use value types (structs, enums) when appropriate to reduce reference counting overhead
* Be mindful of memory usage in closures
* Use Instruments to detect and fix memory leaks

```swift
// Potential retain cycle
class ImageDownloader {
    var completion: ((UIImage) -> Void)?
    
    // Wrong - Creates a retain cycle
    func downloadImage() {
        APIClient.getImage { [self] image in
            self.completion?(image)
        }
    }
    
    // Correct - Avoids retain cycle
    func downloadImage() {
        APIClient.getImage { [weak self] image in
            self?.completion?(image)
        }
    }
}
```

## Collections and Algorithms

* Choose the appropriate collection type for your use case
* Use lazy operations for large collections when appropriate
* Be mindful of algorithmic complexity (O(n), O(log n), etc.)
* Cache results of expensive computations

```swift
// Inefficient - Repeated filtering
func processItems(items: [Item]) {
    let expensiveItems = items.filter { $0.price > 100 }
    let popularExpensiveItems = items.filter { $0.price > 100 && $0.isPopular }
    
    // Process expensiveItems and popularExpensiveItems
}

// Efficient - Filter once and reuse results
func processItems(items: [Item]) {
    let expensiveItems = items.filter { $0.price > 100 }
    let popularExpensiveItems = expensiveItems.filter { $0.isPopular }
    
    // Process expensiveItems and popularExpensiveItems
}
```

## Resource Management

* Reuse expensive resources like formatters, date formatters, and URL sessions
* Release resources explicitly when no longer needed
* Close files and database connections as soon as you're done with them
* Use autorelease pools for temporary resource-intensive operations

```swift
// Inefficient - Creating formatter repeatedly
func formatDates(dates: [Date]) -> [String] {
    return dates.map { date in
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Efficient - Reuse formatter
func formatDates(dates: [Date]) -> [String] {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return dates.map { formatter.string(from: $0) }
}
```

## Concurrency

* Use Grand Central Dispatch (GCD) or Swift Concurrency appropriately
* Avoid blocking the main thread with long-running operations
* Use appropriate quality of service (QoS) levels for different tasks
* Consider using actor isolation to prevent data races

```swift
// Basic concurrency with GCD
func loadData() {
    DispatchQueue.global(qos: .userInitiated).async {
        // Perform expensive operation
        let data = self.fetchLargeDataSet()
        
        DispatchQueue.main.async {
            // Update UI
            self.updateUI(with: data)
        }
    }
}

// Using Swift Concurrency (Swift 5.5+)
func loadData() async {
    // Perform expensive operation
    let data = await fetchLargeDataSet()
    
    // Update UI (on main actor)
    await MainActor.run {
        updateUI(with: data)
    }
}
```

## Image and Graphics Optimization

* Resize images to the appropriate dimensions before displaying
* Use appropriate image formats and compression
* Cache processed images instead of redrawing them
* Optimize Core Graphics and Metal rendering

```swift
// Inefficient - Loading full-size images
let imageView = UIImageView(image: UIImage(named: "large_image.jpg"))

// Efficient - Resize images before display
func optimizedImage(named imageName: String, size: CGSize) -> UIImage? {
    guard let originalImage = UIImage(named: imageName) else { return nil }
    
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
    originalImage.draw(in: CGRect(origin: .zero, size: size))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage
}
```

## Battery Optimization

* Batch network requests to reduce radio usage
* Use background fetch wisely
* Optimize location services usage with proper accuracy settings
* Reduce CPU and GPU intensive operations

```swift
// Conserve battery with appropriate location accuracy
let locationManager = CLLocationManager()

// High battery usage - Unnecessary precision
locationManager.desiredAccuracy = kCLLocationAccuracyBest

// Better for battery - Use only what's needed
locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
``` 