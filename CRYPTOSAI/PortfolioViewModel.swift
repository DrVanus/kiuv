//
//  PortfolioViewModel.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// PortfolioViewModel.swift
import Foundation

class PortfolioViewModel: ObservableObject {
    @Published var holdings: [Holding] = []
    @Published var totalValue: Double = 0.0
    
    func fetchHoldings() {
        // Dummy data for demonstration
        let btc = Coin(id: "bitcoin", name: "Bitcoin", price: 50000)
        let eth = Coin(id: "ethereum", name: "Ethereum", price: 4000)
        holdings = [
            Holding(coin: btc, amount: 0.5),
            Holding(coin: eth, amount: 10)
        ]
        calculateTotalValue()
    }
    
    func calculateTotalValue() {
        totalValue = holdings.reduce(0) { $0 + ($1.coin.price * $1.amount) }
    }
}