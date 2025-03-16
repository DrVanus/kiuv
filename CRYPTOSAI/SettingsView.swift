//
//  SettingsView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Toggle("Dark Mode", isOn: $appState.isDarkMode)
                // Additional settings can go here
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(AppState())
    }
}