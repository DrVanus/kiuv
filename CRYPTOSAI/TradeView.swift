//
//  TradeView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// TradeView.swift
import SwiftUI

struct TradeView: View {
    @StateObject private var viewModel = TradeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // TradingView web chart
                TradingViewWebView()
                    .frame(height: 300)
                
                // Order placement form
                Form {
                    Section(header: Text("Order Type")) {
                        Picker("Type", selection: $viewModel.orderType) {
                            Text("Buy").tag("Buy")
                            Text("Sell").tag("Sell")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Amount")) {
                        TextField("Enter amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Button(action: {
                        viewModel.placeOrder()
                    }) {
                        Text("Place Order")
                    }
                }
            }
            .navigationTitle("Trade")
        }
    }
}

struct TradeView_Previews: PreviewProvider {
    static var previews: some View {
        TradeView()
    }
}
