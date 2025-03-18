//
//  MarketView.swift
//  CRYPTOSAI
//
//  Final Market screen with:
//   - Fixed column widths for both header & rows (Coin, Price, 24h, Volume, Star).
//   - Uniform alignment and spacing, so headers line up perfectly.
//   - Sorting, favorites, search, segments, and pull-to-refresh remain intact.
//

import SwiftUI

// MARK: - MarketCoin Model

struct MarketCoin: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let dailyChange: Double
    let volume: Double
    var isFavorite: Bool = false
    
    // (Optional) For iOS 16+ sparkline data if you want mini-charts
    let sparklineData: [Double] = []
}

// MARK: - SortField + SortDirection

enum SortField: String {
    case coin, price, dailyChange, volume, none
}

enum SortDirection {
    case asc, desc
}

// For the segment filters
enum MarketSegment: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers  = "Losers"
}

// MARK: - ViewModel

class MarketViewModel: ObservableObject {
    @Published var coins: [MarketCoin] = []
    @Published var filteredCoins: [MarketCoin] = []
    
    // Collapsible search
    @Published var showSearchBar: Bool = true
    @Published var searchText: String = ""
    
    // Segment filter
    @Published var selectedSegment: MarketSegment = .all
    
    // Sorting
    @Published var sortField: SortField = .none
    @Published var sortDirection: SortDirection = .asc
    
    // Favorites persistence
    private let favoritesKey = "favoriteCoinSymbols"
    
    init() {
        loadSampleCoins()
        loadFavorites()
        applyAllFiltersAndSort()
    }
    
    private func loadSampleCoins() {
        coins = [
            MarketCoin(symbol: "BTC", name: "Bitcoin",  price: 27950.00, dailyChange: 1.24,  volume: 450_000_000),
            MarketCoin(symbol: "ETH", name: "Ethereum", price: 1800.25,  dailyChange: -0.56, volume: 210_000_000),
            MarketCoin(symbol: "SOL", name: "Solana",   price: 22.00,    dailyChange: 3.44,  volume: 50_000_000),
            MarketCoin(symbol: "XRP", name: "XRP",      price: 0.464,    dailyChange: -3.16, volume: 120_000_000),
            MarketCoin(symbol: "DOGE",name: "Dogecoin", price: 0.080,    dailyChange: 2.15,  volume: 90_000_000),
            MarketCoin(symbol: "ADA", name: "Cardano",  price: 0.390,    dailyChange: 1.05,  volume: 75_000_000)
        ]
    }
    
    // MARK: - Favorites
    private func loadFavorites() {
        let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        for i in coins.indices {
            if saved.contains(coins[i].symbol.uppercased()) {
                coins[i].isFavorite = true
            }
        }
    }
    
    private func saveFavorites() {
        let faves = coins.filter { $0.isFavorite }.map { $0.symbol.uppercased() }
        UserDefaults.standard.setValue(faves, forKey: favoritesKey)
    }
    
    func toggleFavorite(_ coin: MarketCoin) {
        guard let idx = coins.firstIndex(where: { $0.id == coin.id }) else { return }
        withAnimation(.spring()) {
            coins[idx].isFavorite.toggle()
        }
        saveFavorites()
        applyAllFiltersAndSort()
    }
    
    // MARK: - Segment & Search
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }
    
    func updateSearch(_ query: String) {
        searchText = query
        applyAllFiltersAndSort()
    }
    
    // MARK: - Sorting
    func toggleSort(for field: SortField) {
        if sortField == field {
            // flip asc <-> desc
            sortDirection = (sortDirection == .asc) ? .desc : .asc
        } else {
            // new field
            sortField = field
            sortDirection = .asc
        }
        applyAllFiltersAndSort()
    }
    
    // MARK: - Filter & Sort
    func applyAllFiltersAndSort() {
        var result = coins
        
        // 1) search
        let lowerSearch = searchText.lowercased()
        if !lowerSearch.isEmpty {
            result = result.filter {
                $0.symbol.lowercased().contains(lowerSearch) ||
                $0.name.lowercased().contains(lowerSearch)
            }
        }
        
        // 2) segment
        switch selectedSegment {
        case .all: break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .gainers:
            result = result.filter { $0.dailyChange > 0 }
        case .losers:
            result = result.filter { $0.dailyChange < 0 }
        }
        
        // 3) sort
        filteredCoins = sortCoins(result)
    }
    
    private func sortCoins(_ arr: [MarketCoin]) -> [MarketCoin] {
        guard sortField != .none else { return arr }
        
        return arr.sorted { lhs, rhs in
            switch sortField {
            case .coin:
                let compare = lhs.symbol.localizedCaseInsensitiveCompare(rhs.symbol)
                return sortDirection == .asc
                    ? (compare == .orderedAscending)
                    : (compare == .orderedDescending)
            case .price:
                return sortDirection == .asc ? (lhs.price < rhs.price) : (lhs.price > rhs.price)
            case .dailyChange:
                return sortDirection == .asc ? (lhs.dailyChange < rhs.dailyChange) : (lhs.dailyChange > rhs.dailyChange)
            case .volume:
                return sortDirection == .asc ? (lhs.volume < rhs.volume) : (lhs.volume > rhs.volume)
            case .none:
                return false
            }
        }
    }
}

// MARK: - Main View

struct MarketView: View {
    @StateObject private var vm = MarketViewModel()
    
    // Column widths (tweak as you see fit)
    private let coinWidth: CGFloat   = 140
    private let priceWidth: CGFloat  = 80
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 80
    private let starWidth: CGFloat   = 40
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                segmentRow
                if vm.showSearchBar {
                    searchBar
                }
                
                // Table header
                columnHeader
                
                // List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.filteredCoins) { coin in
                            coinRow(coin)
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 16) // align w/ row
                        }
                    }
                    .padding(.bottom, 12)
                }
                .refreshable {
                    // Simulated refresh
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

extension MarketView {
    
    // 1. Top bar
    private var topBar: some View {
        HStack {
            Text("Market")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
            
            Button(action: {
                withAnimation {
                    vm.showSearchBar.toggle()
                }
            }) {
                Image(systemName: vm.showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // 2. Segments
    private var segmentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarketSegment.allCases, id: \.self) { seg in
                    Button(action: {
                        vm.updateSegment(seg)
                    }) {
                        Text(seg.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(vm.selectedSegment == seg ? .black : .white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(vm.selectedSegment == seg ? Color.white : Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    // 3. Search bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search coins...", text: $vm.searchText)
                .foregroundColor(.white)
                .onChange(of: vm.searchText) { newVal in
                    vm.updateSearch(newVal)
                }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // 4. Column header
    private var columnHeader: some View {
        HStack(spacing: 0) {
            // Coin
            headerButton("Coin", .coin)
                .frame(width: coinWidth, alignment: .leading)
            
            // Price
            headerButton("Price", .price)
                .frame(width: priceWidth, alignment: .trailing)
            
            // 24h
            headerButton("24h", .dailyChange)
                .frame(width: dailyWidth, alignment: .trailing)
            
            // Volume
            headerButton("Vol", .volume)
                .frame(width: volumeWidth, alignment: .trailing)
            
            // Star column (no header label)
            Spacer().frame(width: starWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
    }
    
    private func headerButton(_ label: String, _ field: SortField) -> some View {
        Button {
            vm.toggleSort(for: field)
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                if vm.sortField == field {
                    Image(systemName: vm.sortDirection == .asc ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(vm.sortField == field ? Color.white.opacity(0.05) : Color.clear)
    }
    
    // 5. Coin row
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            // Coin
            Button(action: {
                // navigate to detail?
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(coin.symbol.uppercased())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(coin.name)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: coinWidth, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Price
            Text("$\(coin.price, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
            
            // 24h
            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
            
            // Volume
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
            
            // Star
            Button {
                vm.toggleFavorite(coin)
            } label: {
                Image(systemName: coin.isFavorite ? "star.fill" : "star")
                    .foregroundColor(coin.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: starWidth, alignment: .center)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
    
    private func shortVolume(_ vol: Double) -> String {
        switch vol {
        case 1_000_000_000...:
            return String(format: "%.1fB", vol / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", vol / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", vol / 1_000)
        default:
            return String(format: "%.0f", vol)
        }
    }
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
    }
}
