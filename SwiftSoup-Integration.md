# Integrating SwiftSoup with PageWidget

To complete the integration of SwiftSoup with your PageMon widget, follow these steps in Xcode:

## 1. Add SwiftSoup to Your Xcode Project

### Method 1: Using Swift Package Manager in Xcode
1. Open your Xcode project
2. Go to File > Add Package Dependencies...
3. In the search bar, enter: `https://github.com/scinfu/SwiftSoup.git`
4. Click "Add Package"
5. Select your PageWidget target in the next dialog
6. Click "Add Package"

### Method 2: Linking with Our Local Package
Since we've already added SwiftSoup as a dependency to our Package.swift file:

1. In Xcode, select your project in the navigator
2. Select the PageWidget target
3. Go to the "Build Phases" tab
4. Expand "Link Binary With Libraries"
5. Click the "+" button
6. Select "Add Other..." then "Add Files..."
7. Navigate to `.build/debug` and select `libSwiftSoup.dylib` or the appropriate SwiftSoup library file
8. Click "Open"

## 2. Update Build Settings (if needed)

If you're still having issues with importing SwiftSoup:

1. Select your project in the navigator
2. Select the PageWidget target
3. Go to the "Build Settings" tab
4. Find "Import Paths" (you may need to use the search)
5. Add the path to the SwiftSoup module (typically `.build/checkouts/SwiftSoup/Sources` or similar)

## Using SwiftSoup in Your Widget

Once properly integrated, you can use SwiftSoup's powerful CSS selector capabilities:

```swift
// Examples of CSS selectors you can now use:

// Basic selectors
"h1"                    // Select all h1 elements
"div.content"           // Select div elements with class "content"
"#main-header"          // Select element with id "main-header"

// Nested selectors
"div p"                 // Select all p elements inside divs
"article > p"           // Select p elements that are direct children of article

// Attribute selectors
"a[href]"               // Select links with href attribute
"img[src$=.png]"        // Select images with .png extension

// Pseudo-selectors
"p:first-child"         // Select first p element
"tr:nth-child(even)"    // Select even table rows

// Combinators
"div.container, span.highlight"  // Select both div.container and span.highlight
```

These selectors work just like `document.querySelector()` in JavaScript, making it much easier to target the exact content you want from websites.

## Troubleshooting

If you encounter build errors:

1. Make sure the SwiftSoup library is properly linked
2. Check that the import path is correct
3. Clean your build folder (Product > Clean Build Folder)
4. Close and reopen Xcode
5. Try building again

If you still have issues, consider manually downloading the SwiftSoup source and adding it directly to your project. 