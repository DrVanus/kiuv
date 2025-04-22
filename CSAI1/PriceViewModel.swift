//
//  PriceViewModel.swift
//  CSAI1
//
//  Created by DM on 4/22/25.
//


import Foundation
import Combine

@MainActor
class PriceViewModel: ObservableObject {
  @Published var currentPrice: Double?
  private var coin: String
  private var cancellables = Set<AnyCancellable>()
  private let service = CoinbaseService()
  
  init(symbol: String) {
      self.coin = symbol
      // Kick off immediate and recurring fetches for the symbol
      updateSymbol(symbol)
  }
  
  /// Change the symbol being tracked and restart the polling timer
  func updateSymbol(_ newSymbol: String) {
    coin = newSymbol
    // Immediate fetch before starting timer
    Task {
        if let price = await service.fetchSpotPrice(coin: newSymbol) {
            self.currentPrice = price
        }
    }
    // Cancel existing polling subscriptions
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
    // Start polling for the new symbol every 5 seconds
    Timer.publish(every: 5, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        Task {
          guard let self = self,
                let price = await self.service.fetchSpotPrice(coin: newSymbol)
          else { return }
          self.currentPrice = price
        }
      }
      .store(in: &cancellables)
  }
}
