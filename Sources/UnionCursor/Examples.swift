//
//  Examples.swift
//  
//
//  Created by Ben Sage on 10/8/20.
//

import SwiftUI

@available(iOS 16, *)
struct ContentView: View {
    @State var text = ""
    var number = 4
    
    var body: some View {
        ZStack {
            HStack(spacing: 13) {
                ForEach(0..<number, id: \.self) { i in
                    InputNumber(index: i, text: $text)
                }
            }
            TextField("", text: $text)
                .frame(height: 45)
                .foregroundColor(.clear)
                .accentColor(.clear)
                .keyboardType(.decimalPad)
        }
    }
}

@available(iOS 16, *)
struct InputNumber: View {
    var index: Int
    @Binding var text: String
    
    @Environment(\.colorScheme) var colorScheme
    var darkMode: Bool { colorScheme == .dark }
    
    var placeholderWhite: Double { darkMode ? 0.25 : 0.9}
    var numberWhite: Double { darkMode ? 0.65 : 0.5 }
    
    var cursor: some View {
        Cursor(size: 32)
            .tint(Color(red: 0.3, green: 0.76, blue: 0.85))
    }
    var placeholderNumber: some View {
        Text(String(index + 1))
            .font(.system(size: 32))
            .foregroundColor(Color(white: placeholderWhite))
    }
    var inputtedNumber: some View {
        Text(String(text[index]))
            .font(.system(size: 32))
            .foregroundColor(Color(white: numberWhite))
    }
    
    var body: some View {
        VStack {
            if text.count < index {
                placeholderNumber
            } else if text.count == index {
                cursor
            } else {
                inputtedNumber
            }
            Spacer()
            RoundedRectangle(cornerRadius: 1.5)
                .frame(height: 3)
                .foregroundColor(Color(white: text.count >= index ? numberWhite : placeholderWhite))
        }
        .frame(width: 60, height: 45)
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let startIdx = max(0, range.lowerBound)
        let start = index(startIndex, offsetBy: startIdx)
        let end = index(start, offsetBy: min(self.count - startIdx,
                                             range.upperBound - startIdx))
        return String(self[start..<end])
    }
    
    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
}

extension StringProtocol {
    subscript(_ offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }
    subscript(_ range: Range<Int>) -> SubSequence {
        prefix(range.lowerBound + range.count).suffix(range.count)
    }
    subscript(_ range: ClosedRange<Int>) -> SubSequence {
        prefix(range.lowerBound + range.count).suffix(range.count)
    }
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence {
        prefix(range.upperBound.advanced(by: 1))
    }
    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }
    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count - range.lowerBound))
    }
}
