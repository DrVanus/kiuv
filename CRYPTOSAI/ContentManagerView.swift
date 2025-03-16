//
//  ContentManagerView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//

// ContentManagerView.swift
import SwiftUI

struct ContentManagerView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content based on selected tab
            TabView(selection: $appState.selectedTab) {
                HomeView()
                    .tag(CustomTab.home)
                MarketView()
                    .tag(CustomTab.market)
                TradeView()
                    .tag(CustomTab.trade)
                PortfolioView()
                    .tag(CustomTab.portfolio)
                AITabView()
                    .tag(CustomTab.ai)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $appState.selectedTab)
        }
    }
}

struct ContentManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ContentManagerView().environmentObject(AppState())
    }
}
