# UnionCursor

A **blinking cursor** view for SwiftUI that looks and behaves like a real iOS text cursor.

## Usage

```swift
import UnionCursor

// Basic cursor
Cursor()

// Sized cursor with color
Cursor(size: 24)
    .tint(.blue)

// Control blinking while typing
Cursor(size: 16, isTyping: isCurrentlyTyping)
```

## Features

- ✅ Automatic iOS version adaptation (modern async/await on iOS 16+, legacy timers on iOS 13-15)
- ✅ `isTyping` parameter to stop blinking while actively typing
- ✅ Uses `.tint()` on iOS 15+ for proper theming
- ✅ Matches native cursor timing and appearance
- ✅ Fully backward compatible

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/unionst/union-cursor.git", from: "2.0.0")
]
```

That's it! 🎉