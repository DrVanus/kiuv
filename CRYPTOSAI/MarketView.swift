//
//  MarketView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//

// MarketView.swift
import SwiftUI

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search coins...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Coin list
                List(viewModel.coins, id: \.id) { coin in
                    HStack {
                        Text(coin.name)
                        Spacer()
                        Text("$\(coin.price, specifier: "%.2f")")
                    }
                }
            }
            .navigationTitle("Market")
        }
        .onAppear {
            viewModel.fetchCoins()
        }
    }
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
    }
}
