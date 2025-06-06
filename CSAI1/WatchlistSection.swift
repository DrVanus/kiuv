import SwiftUI

// MARK: - AnimatedPriceText
/// Displays the coin’s price with a color flash and a temporary tick icon
/// whenever the price changes. The tick icon (an arrow in a circle) appears
/// briefly to indicate whether the price went up or down.
struct AnimatedPriceText: View {
    let price: Double

    // Store old price locally for comparison
    @State private var oldPrice: Double = 0.0
    // Current text color
    @State private var textColor: Color = .white
    // Temporary tick icon (e.g., "arrow.up.circle.fill" or "arrow.down.circle.fill")
    @State private var tickIcon: String? = nil

    var body: some View {
        HStack(spacing: 2) {
            Text(formatPrice(price))
                .foregroundColor(textColor.opacity(0.7))
                .font(.footnote)
            if let icon = tickIcon {
                Image(systemName: icon)
                    .foregroundColor(textColor.opacity(0.7))
                    .font(.footnote)
            }
        }
        .onAppear {
            oldPrice = price
        }
        .onChange(of: price) { oldVal, newVal in
            guard newVal != oldVal else { return }
            if newVal > oldVal {
                textColor = .green
                tickIcon = "arrow.up.circle.fill"
            } else if newVal < oldVal {
                textColor = .red
                tickIcon = "arrow.down.circle.fill"
            }
            // Revert color & icon after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut) {
                    textColor = .white
                    tickIcon = nil
                }
            }
            oldPrice = newVal
        }
    }

    /// Formats a price value into a currency string.
    private func formatPrice(_ value: Double) -> String {
        guard value > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if value < 1.0 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }
}

// MARK: - ChangeView
struct ChangeView: View {
    let label: String
    let change: Double

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Text(change >= 0
                ? "▲\(String(format: "%.2f%%", change))"
                : "▼\(String(format: "%.2f%%", abs(change)))")
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(change >= 0 ? .green : .red)
        }
        .frame(width: 80, alignment: .trailing)
    }
}

// MARK: - WatchlistSectionView
struct WatchlistSectionView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @Binding var isEditingWatchlist: Bool

    // Local state for "Show More / Show Less"
    @State private var showAll = false

    // Timer to auto-refresh watchlist data (every 15 seconds)
    @State private var refreshTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    // Compute the user’s watchlist (all favorite coins)
    private var liveWatchlist: [MarketCoin] {
        marketVM.coins.filter { $0.isFavorite }
    }

    // How many coins to show when collapsed
    private let maxVisible = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Your Watchlist", iconName: "eye")

            if liveWatchlist.isEmpty {
                emptyWatchlistView
            } else {
                let coinsToShow = showAll ? liveWatchlist : Array(liveWatchlist.prefix(maxVisible))
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                    List {
                        ForEach(coinsToShow, id: \.id) { coin in
                            VStack(spacing: 0) {
                                rowContent(for: coin)
                                // Uncomment the next line for a subtle divider:
                                // Divider().background(Color.white.opacity(0.2))
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        .onMove(perform: moveCoinInWatchlist)
                    }
                    .listStyle(.plain)
                    .listRowSpacing(0)
                    .scrollDisabled(true)
                    .frame(height: showAll ? CGFloat(liveWatchlist.count) * 45 : CGFloat(maxVisible) * 45)
                    .animation(.easeInOut, value: showAll)
                    .environment(\.editMode, .constant(isEditingWatchlist ? .active : .inactive))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)

                if liveWatchlist.count > maxVisible {
                    Button {
                        withAnimation(.spring()) {
                            showAll.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAll ? "Show Less" : "Show More")
                                .font(.callout)
                                .foregroundColor(.white)
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white)
                                .font(.footnote)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        // Auto-refresh the data every 15 seconds (currently updating only price changes)
        .onReceive(refreshTimer) { _ in
            marketVM.fetchLivePricesFromCoinbase()
        }
        .onAppear {
            marketVM.fetchLivePricesFromCoinbase()
        }
    }

    // MARK: - Empty Watchlist View
    private var emptyWatchlistView: some View {
        VStack(spacing: 16) {
            Text("No coins in your watchlist yet.")
                .font(.callout)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Row Content
    private func rowContent(for coin: MarketCoin) -> some View {
        HStack(spacing: 8) {
            // Left accent bar (gold gradient)
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            // Coin icon and basic info
            coinIconView(for: coin, size: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.white)
                // Price with animated flash and tick icon on the right
                AnimatedPriceText(price: coin.price)
            }
            Spacer()
            // 1H and 24H percentage changes with arrow icons
            HStack(spacing: 16) {
                ChangeView(label: "1H:", change: coin.hourlyChange)
                ChangeView(label: "24H:", change: coin.dailyChange)
            }
            .font(.caption2)
            .animation(.easeInOut, value: coin.hourlyChange)
            .animation(.easeInOut, value: coin.dailyChange)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index = marketVM.coins.firstIndex(where: { $0.id == coin.id }) {
                    marketVM.coins[index].isFavorite = false
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: - Reordering (Drag and Drop)
    private func moveCoinInWatchlist(from source: IndexSet, to destination: Int) {
        var favorites = marketVM.coins.filter { $0.isFavorite }
        favorites.move(fromOffsets: source, toOffset: destination)
        let nonFavorites = marketVM.coins.filter { !$0.isFavorite }
        marketVM.coins = nonFavorites + favorites
        withAnimation(.spring()) { }
    }

    // MARK: - Helpers (Formatting and Image)
    private func coinIconView(for coin: MarketCoin, size: CGFloat) -> some View {
        Group {
            if let imageUrl = coin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size, height: size)
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
    }

    private func sectionHeading(_ text: String, iconName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(.yellow)
                }
                Text(text)
                    .font(.title3).bold()
                    .foregroundColor(.white)
            }
            Divider()
                .background(Color.white.opacity(0.15))
        }
    }
}
