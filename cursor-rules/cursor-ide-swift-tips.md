# Cursor IDE Swift Development Tips

## Cursor-Specific Shortcuts for Swift

* Use `⌘ + Shift + F` to format Swift code
* Use `⌘ + Click` on a symbol to navigate to its definition
* Use `⌘ + Shift + O` to quickly open files by name
* Use `⌘ + P` for parameter hints in functions and methods
* Use `⌘ + F12` to see the structure of the current file

## Swift Code Snippets in Cursor

Create and use code snippets for common Swift patterns to improve productivity. Here are some useful snippets to configure:

### Property with Property Wrapper

```swift
@Published var ${1:propertyName}: ${2:Type}${3: = ${4:defaultValue}}
```

### MARK Comment Section

```swift
// MARK: - ${1:Section Name}
```

### UITableView Data Source Methods

```swift
// MARK: - UITableViewDataSource

extension ${1:ClassName}: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ${2:count}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "${3:cellIdentifier}", for: indexPath) as! ${4:CellType}
        ${5:// Configure cell}
        return cell
    }
}
```

### SwiftUI View Template

```swift
struct ${1:ViewName}: View {
    var body: some View {
        ${2:Text("Hello, World!")}
    }
}

struct ${1:ViewName}_Previews: PreviewProvider {
    static var previews: some View {
        ${1:ViewName}()
    }
}
```

## Cursor Project Configuration for Swift

* Set up recommended file association for Swift files (`.swift`, `.xib`, `.storyboard`)
* Configure linting rules for Swift files using SwiftLint integration
* Set up auto-formatting on save using Swift formatting rules
* Configure build tasks for Swift projects

```json
// Example Cursor settings.json configuration for Swift projects
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "com.cursor.cursor-swift-formatter",
  "swift.lint.enabled": true,
  "swift.lint.configFile": ".swiftlint.yml",
  "swift.buildOnSave": true,
  "swift.path": "/usr/bin/swift",
  "swift.diagnostics.experimental": true
}
```

## Swift Analysis and Refactoring in Cursor

* Use Cursor's code analysis tools to identify:
  * Memory leaks (e.g., retain cycles)
  * Performance bottlenecks
  * Code style violations
  * Potential bugs

* Common refactoring operations:
  * Extract Method: Select code and use `⌘ + Alt + M`
  * Rename Symbol: Position cursor on symbol and press `F2`
  * Change Method Signature: Right-click on method and select "Change Method Signature"
  * Convert between `if let` and `guard let`

## Xcode Integration Tips

* Configure Cursor to work alongside Xcode
* Set up external tools to open the current file in Xcode when needed
* Use version control integration to sync changes between Cursor and Xcode

```bash
# Example script to open current file in Xcode
open -a Xcode "${CURSOR_FILEPATH}"
```

## Swift Package Manager Integration

* Configure Swift Package Manager commands in Cursor
* Use terminal integration to run Swift Package Manager commands
* Set up custom tasks for common Swift Package Manager operations

```json
// Example tasks.json for Swift Package Manager
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "swift: build",
      "type": "shell",
      "command": "swift build",
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "swift: test",
      "type": "shell",
      "command": "swift test",
      "group": {
        "kind": "test",
        "isDefault": true
      }
    },
    {
      "label": "swift: clean",
      "type": "shell",
      "command": "swift package clean"
    },
    {
      "label": "swift: update",
      "type": "shell",
      "command": "swift package update"
    }
  ]
}
```

## Debugging Swift in Cursor

* Set up LLDB integration for Swift debugging
* Configure launch configurations for debugging Swift applications
* Use breakpoints and watchpoints effectively
* View variables and memory during debugging sessions

```json
// Example launch.json for Swift debugging
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug Swift Application",
      "program": "${workspaceFolder}/.build/debug/MyApp",
      "args": [],
      "cwd": "${workspaceFolder}",
      "preLaunchTask": "swift: build"
    }
  ]
}
``` 