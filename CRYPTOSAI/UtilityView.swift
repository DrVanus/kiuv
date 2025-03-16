//
//  CardView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// UtilityViews.swift
import SwiftUI

// A reusable card view with rounded corners and shadow.
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.secondarySystemBackground))
            .shadow(radius: 5)
            .overlay(content)
            .padding()
    }
}

// A simple trending card view that shows a trending coin label.
struct TrendingCard: View {
    var coin: String
    var body: some View {
        CardView {
            Text("Trending: \(coin)")
                .font(.headline)
        }
    }
}

// Define a basic ChatMessage type so ChatBubble can compile.
struct ChatMessage: Identifiable {
    var id = UUID()
    var sender: String  // "user" or "ai"
    var text: String
}

// A chat bubble view that displays a message with conditional styling.
struct ChatBubble: View {
    var message: ChatMessage
    var body: some View {
        HStack {
            if message.sender == "ai" { Spacer() }
            Text(message.text)
                .padding()
                .background(message.sender == "ai" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(10)
            if message.sender == "user" { Spacer() }
        }
        .padding(message.sender == "ai" ? .leading : .trailing)
    }
}
