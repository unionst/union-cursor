//
//  Cursor.swift
//  union-cursor
//
//  Created by Ben Sage on 10/5/20.
//

import SwiftUI
import Combine

/// A **blinking cursor** view that looks and behaves like a real iOS text cursor.
///
/// `Cursor` automatically adapts to different iOS versions, using modern async/await animations
/// on iOS 16+ and legacy Timer-based animations on iOS 13-15. The cursor supports both
/// blinking and solid states based on typing activity.
///
/// ## Example Usage
///
/// **Basic cursor:**
/// ```swift
/// Cursor()
/// ```
///
/// **Sized cursor with typing state:**
/// ```swift
/// Cursor(size: 24, isTyping: false)
///     .tint(.blue)
/// ```
///
/// **Text field cursor:**
/// ```swift
/// HStack {
///     Text("Hello")
///     if isEditing {
///         Cursor(size: 16, isTyping: isTyping)
///             .tint(.accentColor)
///     }
/// }
/// ```
@available(iOS 13.0, *)
public struct Cursor: View {
    private let size: CGFloat
    private let isTyping: Bool
    private var foregroundColor: Color?
    @State private var on: Bool = true
    @State private var blinkTask: Task<Void, Never>?

    /// Creates a cursor with the specified size and typing state.
    ///
    /// Use this initializer for the modern API that supports the `isTyping` parameter
    /// to control blinking behavior.
    ///
    /// - Parameters:
    ///   - size: The font size the cursor should match, in points. Defaults to 14.0.
    ///   - isTyping: Whether the cursor should remain solid (true) or blink (false). Defaults to false.
    ///
    /// ## Example
    /// ```swift
    /// // Standard blinking cursor
    /// Cursor(size: 18)
    ///
    /// // Solid cursor while typing
    /// Cursor(size: 20, isTyping: true)
    ///     .tint(.red)
    /// ```
    public init(size: CGFloat = 14.0, isTyping: Bool = false) {
        self.size = size
        self.isTyping = isTyping
    }
    
    /// Creates a cursor with default size and blinking enabled.
    ///
    /// This is the legacy initializer for backward compatibility. For new code,
    /// consider using `init(size:isTyping:)` instead.
    ///
    /// ## Example
    /// ```swift
    /// Cursor()
    ///     .fontSize(16)
    ///     .foregroundColor(.blue)
    /// ```
    public init() {
        self.size = 14.0
        self.isTyping = false
    }
    
    /// The content and behavior of the cursor view.
    ///
    /// This property creates the visual representation of the cursor and handles
    /// its blinking animations based on the iOS version and typing state.
    public var body: some View {
        ZStack {
            filledRectangle
                .frame(width: 2, height: (2.29925 * size + 3.28947) / 2)
                .opacity(isTyping ? 1 : (on ? 1 : 0))
        }
        .onAppear {
            if !isTyping {
                startBlinking()
            }
        }
        .onDisappear {
            stopBlinking()
        }
        .modifier(
            TypingChangeModifier(
                isTyping: isTyping,
                onTypingChanged: { newValue in
                    if newValue {
                        stopBlinking()
                        on = true
                    } else {
                        startBlinking()
                    }
                }
            )
        )
    }
    
    @ViewBuilder
    private var filledRectangle: some View {
        if #available(iOS 15.0, *) {
            RoundedRectangle(cornerRadius: 1)
                .fill(.tint)
        } else {
            RoundedRectangle(cornerRadius: 1)
                .fill(foregroundColor ?? Color.blue)
        }
    }
    
    private func startBlinking() {
        if #available(iOS 16.0, *) {
            startModernBlinking()
        } else {
            startLegacyBlinking()
        }
    }
    
    private func stopBlinking() {
        if #available(iOS 16.0, *) {
            blinkTask?.cancel()
        }
    }
    
    @available(iOS 16.0, *)
    @MainActor
    private func startModernBlinking() {
        blinkTask?.cancel()
        blinkTask = Task {
            await modernBlinkingLoop()
        }
    }
    
    @available(iOS 16.0, *)
    @MainActor
    private func modernBlinkingLoop() async {
        while !Task.isCancelled {
            on = true
            try? await Task.sleep(for: .milliseconds(Int(32.0/60.0 * 1000)))
            
            if Task.isCancelled { return }
            
            withAnimation(.spring(duration: 8.0 / 60.0)) {
                self.on = false
            }
            try? await Task.sleep(for: .milliseconds(Int(8.0/60.0 * 1000)))
            
            if Task.isCancelled { return }
            
            try? await Task.sleep(for: .milliseconds(Int(14.0/60.0 * 1000)))
            
            if Task.isCancelled { return }
            
            withAnimation(.spring(duration: 8.0 / 60.0)) {
                self.on = true
            }
            try? await Task.sleep(for: .milliseconds(Int(8.0/60.0 * 1000)))
        }
    }
    
    private func startLegacyBlinking() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.legacyBlinkCursor()
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.legacyBlinkCursor()
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func legacyBlinkCursor() {
        withAnimation(.easeInOut(duration: 12.0 / 60.0)) {
            self.on = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 29.0 / 60.0) {
            withAnimation(.easeInOut(duration: 8.0 / 60.0)) {
                self.on = true
            }
        }
    }
}

@available(iOS 13.0, *)
extension Cursor {
    /// Modifies the **color** of the cursor.
    ///
    /// This method is deprecated on iOS 16+. Use the `.tint()` modifier instead
    /// for better integration with the system design language.
    ///
    /// - Parameter color: The desired cursor color. Pass `nil` to use the default blue color.
    /// - Returns: A cursor with the modified color.
    ///
    /// ## Example
    /// ```swift
    /// // Legacy API (deprecated on iOS 16+)
    /// Cursor()
    ///     .foregroundColor(.red)
    ///
    /// // Modern API (recommended)
    /// Cursor(size: 16)
    ///     .tint(.red)
    /// ```
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "Use .tint() modifier or Cursor(size:) initializer instead")
    public func foregroundColor(_ color: Color?) -> Cursor {
        var view = self
        view.foregroundColor = color
        return view
    }
    
    /// Modifies the **font size** that the cursor is expected to fit.
    ///
    /// This method is deprecated on iOS 16+. Use the `Cursor(size:)` initializer instead
    /// for better performance and API consistency.
    ///
    /// - Parameter size: The font size to be paired with the cursor, in points.
    /// - Returns: A cursor with modified size based on expected font size.
    ///
    /// ## Example
    /// ```swift
    /// // Legacy API (deprecated on iOS 16+)
    /// Cursor()
    ///     .fontSize(24)
    ///     .foregroundColor(.blue)
    ///
    /// // Modern API (recommended)
    /// Cursor(size: 24)
    ///     .tint(.blue)
    /// ```
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "Use Cursor(size:) initializer instead")
    public func fontSize(_ size: CGFloat) -> Cursor {
        return Cursor(size: size, isTyping: self.isTyping)
            .foregroundColor(self.foregroundColor)
    }
}

@available(iOS 13.0, *)
private struct TypingChangeModifier: ViewModifier {
    let isTyping: Bool
    let onTypingChanged: (Bool) -> Void
    @State private var previousValue: Bool?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if previousValue != isTyping {
                    previousValue = isTyping
                    onTypingChanged(isTyping)
                }
            }
            .onReceive(Just(isTyping)) { newValue in
                if let previous = previousValue, previous != newValue {
                    previousValue = newValue
                    onTypingChanged(newValue)
                }
            }
    }
}
