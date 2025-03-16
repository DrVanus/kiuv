// HomeViewModel.swift
import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var watchlistCoins: [CoinGeckoCoin] = []
    // ...
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchData() {
        // ...
    }
    
    // etc.
}
