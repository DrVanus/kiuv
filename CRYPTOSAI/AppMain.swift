//
//  CryptoSageAIApp.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//

import SwiftUI

@main
struct CryptoSageAIApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentManagerView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}
