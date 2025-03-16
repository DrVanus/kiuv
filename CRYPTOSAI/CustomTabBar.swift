//
//  CustomTab.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//

//
//  CustomTabBar.swift
//  CRYPTOSAI
//
//  Improved tab bar icons for a cleaner look
//

import SwiftUI

enum CustomTab: String, CaseIterable {
    case home, market, trade, portfolio, ai
}

struct CustomTabBar: View {
    @Binding var selectedTab: CustomTab
    
    var body: some View {
        HStack {
            ForEach(CustomTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: iconName(for: tab))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 2)
    }
    
    private func iconName(for tab: CustomTab) -> String {
        switch tab {
        case .home:
            return "house.fill"
        case .market:
            return "chart.bar.fill"
        case .trade:
            // You can use "arrow.triangle.swap", "arrow.left.arrow.right", etc.
            return "arrow.left.arrow.right"
        case .portfolio:
            // Could also try "chart.pie.fill" or "wallet.pass.fill"
            return "chart.pie.fill"
        case .ai:
            // Could also try "bubble.left.and.bubble.right.fill" or "lightbulb.fill"
            return "brain.head.profile"
        }
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBar(selectedTab: .constant(.home))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
