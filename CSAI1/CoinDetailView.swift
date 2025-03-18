//
//  CoinDetailView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  CoinDetailView.swift
//  CRYPTOSAI
//
//  Shows details for a specific coin, referencing CoinGeckoCoin.
//

import SwiftUI

struct CoinDetailView: View {
    let coin: CoinGeckoCoin
    
    var body: some View {
        NavigationView {
            VStack {
                Text(coin.name ?? coin.id)
                    .font(.largeTitle)
                
                Text("Price: $\(coin.current_price ?? 0, specifier: "%.2f")")
                    .font(.headline)
                
                // Additional stats or a TradingView chart, etc.
                
            }
            .navigationTitle("Coin Details")
        }
    }
}

struct CoinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CoinDetailView(
            coin: CoinGeckoCoin(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                image: nil,
                current_price: 28000,
                market_cap: nil,
                market_cap_rank: nil,
                total_volume: nil,
                high_24h: nil,
                low_24h: nil,
                price_change_24h: nil,
                price_change_percentage_24h: nil,
                fully_diluted_valuation: nil,
                circulating_supply: nil,
                total_supply: nil,
                ath: nil,
                ath_change_percentage: nil,
                ath_date: nil,
                atl: nil,
                atl_change_percentage: nil,
                atl_date: nil,
                last_updated: nil,
                coin_id: nil,
                thumb: nil,
                small: nil,
                large: nil,
                slug: nil
            )
        )
    }
}
