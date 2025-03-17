//
//  MarketViewModel.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  MarketViewModel.swift
//  CRYPTOSAI
//
//  Demonstrates a separate list of coins, also referencing CoinGeckoCoin.
//

import Foundation
import Combine

class MarketViewModel: ObservableObject {
    @Published var coins: [CoinGeckoCoin] = []
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchCoins() {
        // Example: fetch top 100 coins from CoinGecko
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [CoinGeckoCoin].self, decoder: JSONDecoder())
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.coins, on: self)
            .store(in: &cancellables)
    }
}
