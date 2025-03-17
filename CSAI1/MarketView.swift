//
//  MarketView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  MarketView.swift
//  CRYPTOSAI
//
//  Displays a searchable list of CoinGeckoCoin.
//

import SwiftUI

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search coins...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Coin list
                List {
                    ForEach(filteredCoins, id: \.id) { coin in
                        HStack {
                            Text(coin.symbol.uppercased())
                            Spacer()
                            Text("$\(coin.current_price ?? 0, specifier: "%.2f")")
                        }
                    }
                }
            }
            .navigationTitle("Market")
        }
        .onAppear {
            viewModel.fetchCoins()
        }
    }
    
    private var filteredCoins: [CoinGeckoCoin] {
        if viewModel.searchText.isEmpty {
            return viewModel.coins
        } else {
            return viewModel.coins.filter { coin in
                coin.name?.localizedCaseInsensitiveContains(viewModel.searchText) == true ||
                coin.symbol.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
    }
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
    }
}
