//
//  TradeViewModel.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// TradeViewModel.swift
import Foundation

class TradeViewModel: ObservableObject {
    @Published var orderType: String = "Buy"
    @Published var amount: String = ""
    
    func placeOrder() {
        // Implement order placement logic, validations, API call to trading API etc.
        print("Placing \(orderType) order for amount: \(amount)")
    }
}