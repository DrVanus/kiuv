import SwiftUI

class TradeViewModel: ObservableObject {
    @Published var selectedSymbol: String = "BTC-USD"
    @Published var side: String = "Buy"
    @Published var orderType: String = "Market"
    @Published var quantity: String = ""
    @Published var limitPrice: String = ""
    @Published var userBalance: Double = 5000.0
    @Published var showAdvanced: Bool = false
    
    let symbolOptions = ["BTC-USD", "ETH-USD", "SOL-USD"]
    let orderTypes = ["Market", "Limit", "Stop-Limit", "Trailing Stop"]
    
    // Convert symbol for TradingView embed.
    var convertedSymbol: String {
        switch selectedSymbol {
        case "BTC-USD": return "BINANCE:BTCUSDT"
        case "ETH-USD": return "BINANCE:ETHUSDT"
        case "SOL-USD": return "BINANCE:SOLUSDT"
        default: return "BINANCE:BTCUSDT"
        }
    }
    
    // Simulate quick fraction calculation.
    func applyFraction(_ fraction: Double) {
        let currentPrice = 20000.0  // Dummy price – replace with live data later.
        let amountToSpend = userBalance * fraction
        let calculatedQuantity = amountToSpend / currentPrice
        quantity = String(format: "%.4f", calculatedQuantity)
    }
    
    // Simulated order submission.
    func submitOrder() {
        guard let qty = Double(quantity), qty > 0 else {
            print("Invalid quantity")
            return
        }
        
        if orderType != "Market" {
            guard let price = Double(limitPrice), price > 0 else {
                print("Invalid price for \(orderType) order")
                return
            }
        }
        
        let executionPrice = orderType == "Market" ? 20000.0 : (Double(limitPrice) ?? 20000.0)
        let totalCost = qty * executionPrice
        
        if side == "Buy" {
            if totalCost > userBalance {
                print("Insufficient balance")
                return
            }
            userBalance -= totalCost
            print("Bought \(qty) of \(selectedSymbol) for $\(totalCost)")
        } else {
            userBalance += totalCost
            print("Sold \(qty) of \(selectedSymbol) for $\(totalCost)")
        }
        
        // Clear order fields.
        quantity = ""
        limitPrice = ""
    }
}
