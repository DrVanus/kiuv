//
//  HomeViewModel.swift
//  CRYPTOSAI
//
//  Minimal model with no CoinItem struct.

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var portfolioValue: Double = 65000
    @Published var dailyChangePercentage: Double = 2.34
    
    // Watchlist as simple strings
    @Published var watchlist: [String] = ["BTC", "ETH", "SOL"]
    
    // Trending coins as strings
    @Published var trendingCoins: [String] = ["XRP", "DOGE", "ADA"]
    
    // News headlines
    @Published var newsHeadlines: [String] = [
        "BTC Approaches $100K",
        "XRP Gains Legal Clarity",
        "ETH2 Merge Update"
    ]
    
    func fetchData() {
        // If you want to update from an API, do it here.
    }
}
