//
//  PortfolioView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// PortfolioView.swift
import SwiftUI

struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Total Portfolio Value: \(viewModel.totalValue, specifier: "%.2f")")
                    .font(.largeTitle)
                    .padding()
                
                List(viewModel.holdings, id: \.coin.id) { holding in
                    HStack {
                        Text(holding.coin.name)
                        Spacer()
                        Text("\(holding.amount, specifier: "%.2f")")
                    }
                }
            }
            .navigationTitle("Portfolio")
        }
        .onAppear {
            viewModel.fetchHoldings()
        }
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
}