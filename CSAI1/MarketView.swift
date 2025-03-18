import SwiftUI
import Charts  // for sparkline if iOS 16+

// Example MarketCoin model must exist somewhere (Models.swift or here)
struct MarketCoin: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let dailyChange: Double
    let volume: Double
    var isFavorite: Bool = false
    
    // Sparkline 7-day placeholder
    let sparkline7d: [Double]
}

// Example segment filter
enum MarketSegment: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers  = "Losers"
}

// Example sort fields
enum SortField: String {
    case coin, price, dailyChange, volume, none
}

enum SortDirection {
    case asc, desc
}

// Example MarketViewModel placeholder
class MarketViewModel: ObservableObject {
    @Published var coins: [MarketCoin] = []
    @Published var filteredCoins: [MarketCoin] = []
    
    // For search
    @Published var showSearchBar: Bool = true
    @Published var searchText: String = ""
    
    // Segment
    @Published var selectedSegment: MarketSegment = .all
    
    // Sorting
    @Published var sortField: SortField = .none
    @Published var sortDirection: SortDirection = .asc
    
    init() {
        // Load sample coins
        coins = [
            MarketCoin(symbol: "BTC", name: "Bitcoin",  price: 27950.00, dailyChange: 1.24,  volume: 450_000_000, sparkline7d: [27_000, 27_400, 27_100, 28_000, 28_200, 27_900, 27_950]),
            MarketCoin(symbol: "ETH", name: "Ethereum", price: 1800.25,  dailyChange: -0.56, volume: 210_000_000, sparkline7d: [1800, 1815, 1790, 1825, 1830, 1795, 1800]),
            MarketCoin(symbol: "SOL", name: "Solana",   price: 22.00,    dailyChange: 3.44,  volume: 50_000_000,  sparkline7d: [20, 21, 19.5, 22.3, 23, 22.5, 22]),
            MarketCoin(symbol: "XRP", name: "XRP",      price: 0.464,    dailyChange: -3.16, volume: 120_000_000, sparkline7d: [0.47, 0.48, 0.45, 0.46, 0.44, 0.46, 0.464]),
            MarketCoin(symbol: "DOGE",name: "Dogecoin", price: 0.080,    dailyChange: 2.15,  volume: 90_000_000,  sparkline7d: [0.078, 0.079, 0.081, 0.08, 0.083, 0.079, 0.080]),
            MarketCoin(symbol: "ADA", name: "Cardano",  price: 0.390,    dailyChange: 1.05,  volume: 75_000_000,  sparkline7d: [0.39, 0.40, 0.38, 0.41, 0.40, 0.395, 0.390])
        ]
        applyAllFiltersAndSort()
    }
    
    func toggleFavorite(_ coin: MarketCoin) {
        guard let idx = coins.firstIndex(where: { $0.id == coin.id }) else { return }
        coins[idx].isFavorite.toggle()
        applyAllFiltersAndSort()
    }
    
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }
    
    func updateSearch(_ query: String) {
        searchText = query
        applyAllFiltersAndSort()
    }
    
    func toggleSort(for field: SortField) {
        if sortField == field {
            sortDirection = (sortDirection == .asc) ? .desc : .asc
        } else {
            sortField = field
            sortDirection = .asc
        }
        applyAllFiltersAndSort()
    }
    
    func applyAllFiltersAndSort() {
        var result = coins
        
        // Search
        let lower = searchText.lowercased()
        if !lower.isEmpty {
            result = result.filter {
                $0.symbol.lowercased().contains(lower) ||
                $0.name.lowercased().contains(lower)
            }
        }
        
        // Segment
        switch selectedSegment {
        case .all: break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .gainers:
            result = result.filter { $0.dailyChange > 0 }
        case .losers:
            result = result.filter { $0.dailyChange < 0 }
        }
        
        // Sort
        result = sortCoins(result)
        
        filteredCoins = result
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

struct MarketView: View {
    @StateObject private var vm = MarketViewModel()
    
    // Column widths
    private let coinWidth: CGFloat   = 140
    private let dayWidth: CGFloat    = 50  // for sparkline label or day range
    private let priceWidth: CGFloat  = 70
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 80
    private let starWidth: CGFloat   = 40
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topBar
                    segmentRow
                    if vm.showSearchBar {
                        searchBar
                    }
                    
                    columnHeader
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.filteredCoins) { coin in
                                NavigationLink(destination: CoinDetailView(coin: coin)) {
                                    coinRow(coin)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.leading, 0)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .refreshable {
                        // pull to refresh
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Subviews
extension MarketView {
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
    
    private var columnHeader: some View {
        HStack(spacing: 0) {
            headerButton("Coin", .coin)
                .frame(width: coinWidth, alignment: .leading)
            // Example to show "7D" or time range label:
            Text("7D")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: dayWidth, alignment: .trailing)
            headerButton("Price", .price)
                .frame(width: priceWidth, alignment: .trailing)
            headerButton("24h", .dailyChange)
                .frame(width: dailyWidth, alignment: .trailing)
            headerButton("Vol", .volume)
                .frame(width: volumeWidth, alignment: .trailing)
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
    
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            // coin symbol + name
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
            
            // sparkline (7-day)
            sparkline(coin.sparkline7d)
                .frame(width: dayWidth, height: 20)
            
            // price
            Text("$\(coin.price, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
            
            // daily
            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
            
            // volume
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
            
            // star
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
    
    // Minimal sparkline using Swift Charts (iOS 16+)
    @ViewBuilder
    private func sparkline(_ data: [Double]) -> some View {
        if #available(iOS 16, *) {
            Chart {
                ForEach(data.indices, id: \.self) { i in
                    let val = data[i]
                    LineMark(
                        x: .value("Index", i),
                        y: .value("Price", val)
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        } else {
            // fallback
            Rectangle()
                .fill(Color.gray.opacity(0.3))
        }
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
