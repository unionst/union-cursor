//
//  Cursor.swift
//  union-cursor
//
//  Created by Ben Sage on 10/5/20.
//

import SwiftUI
import Combine

@available(iOS 13.0, *)
public struct Cursor: View {
    private let size: CGFloat
    private let isTyping: Bool
    private var foregroundColor: Color?
    @State private var on: Bool = true
    @State private var blinkTask: Task<Void, Never>?

    public init(size: CGFloat = 14.0, isTyping: Bool = false) {
        self.size = size
        self.isTyping = isTyping
    }
    
    public init() {
        self.size = 14.0
        self.isTyping = false
    }
    
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
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "Use .tint() modifier or Cursor(size:) initializer instead")
    public func foregroundColor(_ color: Color?) -> Cursor {
        var view = self
        view.foregroundColor = color
        return view
    }
    
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
