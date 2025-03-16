//
//  CoinDetailView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// CoinDetailView.swift
import SwiftUI

struct CoinDetailView: View {
    var coin: Coin
    
    var body: some View {
        NavigationView {
            VStack {
                // Example Chart
                TradingViewWebView()
                    .frame(height: 300)
                
                // Market Stats
                Text("\(coin.name) - \(coin.id)")
                    .font(.title)
                
                Text("Price: $\(coin.price, specifier: "%.2f")")
                    .font(.headline)
            }
            .navigationTitle("Coin Details")
        }
    }
}

struct CoinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CoinDetailView(coin: Coin(id: "bitcoin", name: "Bitcoin", price: 50000))
    }
}