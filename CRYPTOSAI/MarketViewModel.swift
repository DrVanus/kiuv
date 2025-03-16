//
//  MarketViewModel.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//

// MarketViewModel.swift
import Foundation
import Combine

class MarketViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var searchText: String = ""
    
    func fetchCoins() {
        // Implement API call to CoinGecko, etc.
        // Dummy data for now:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coins = [
                Coin(id: "bitcoin", name: "Bitcoin", price: 50000),
                Coin(id: "ethereum", name: "Ethereum", price: 4000)
            ]
        }
    }
}
