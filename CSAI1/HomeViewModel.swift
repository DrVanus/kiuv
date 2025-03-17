import Foundation
import Combine

// A simple struct representing a coin in the watchlist
struct CoinItem: Identifiable {
    let id = UUID()
    let symbol: String   // e.g. "BTC"
    let price: Double    // e.g. 28000
    let change24h: Double // e.g. +2.1
}

class HomeViewModel: ObservableObject {
    // Portfolio summary placeholders
    @Published var portfolioValue: Double = 65000
    @Published var dailyChangePercentage: Double = 2.34
    @Published var dailyChangeAmount: Double = 1500
    
    // AI insight placeholder
    @Published var aiInsight: String = "Your portfolio rose 2.3% in the last 24 hours."
    
    // Example watchlist
    @Published var watchlist: [CoinItem] = [
        CoinItem(symbol: "BTC", price: 28000, change24h: 2.1),
        CoinItem(symbol: "ETH", price: 1800, change24h: 1.4),
        CoinItem(symbol: "SOL", price: 22, change24h: -3.0)
    ]
    
    // Trending coins (simple string placeholders)
    @Published var trendingCoins: [String] = ["XRP", "DOGE", "ADA"]
    
    // News headlines (string placeholders)
    @Published var newsHeadlines: [String] = [
        "BTC Approaches $100K",
        "XRP Gains Legal Clarity",
        "ETH2 Merge Update"
    ]
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchData() {
        // If you want real data later, add your API calls here.
        // For now, it's just placeholders.
    }
}
