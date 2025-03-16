//
//  HomeView.swift
//  CRYPTOSAI
//
//  Demonstrates watchlist with sparkline mini-charts (iOS 16+).
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // 1. Portfolio Summary
                    portfolioSummarySection
                    
                    // 2. AI Insight
                    aiHighlightSection
                    
                    // 3. Quick Actions
                    quickActionsSection
                    
                    // 4. Watchlist
                    watchlistSection
                }
                .padding()
                .navigationTitle("Home")
            }
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}

extension HomeView {
    private var portfolioSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Portfolio Value:")
                .font(.headline)
            Text("$\(viewModel.portfolioValue, specifier: "%.2f")")
                .font(.largeTitle)
                .bold()
            
            Text("Daily Change: \(viewModel.dailyChangePercentage, specifier: "%.2f")%  (+$\(viewModel.dailyChangeAmount, specifier: "%.2f"))")
                .foregroundColor(viewModel.dailyChangePercentage >= 0 ? .green : .red)
                .font(.subheadline)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var aiHighlightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Insight")
                .font(.headline)
            Text(viewModel.aiInsight)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            QuickActionButton(label: "Connect", systemIcon: "link.circle") {
                // Action
            }
            QuickActionButton(label: "Trade", systemIcon: "arrow.left.arrow.right.circle") {
                // Action
            }
            QuickActionButton(label: "AI Chat", systemIcon: "bubble.left.and.bubble.right.fill") {
                // Action
            }
        }
    }
    
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watchlist")
                .font(.headline)
            
            if viewModel.watchlistCoins.isEmpty {
                Text("Loading coins...")
                    .foregroundColor(.gray)
            } else {
                ForEach(viewModel.watchlistCoins) { coin in
                    WatchlistRow(coin: coin,
                                 sparkline: viewModel.sparklineData[coin.id] ?? [])
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct WatchlistRow: View {
    let coin: CoinGeckoCoin
    let sparkline: [Double]
    
    var body: some View {
        HStack {
            // Symbol & name
            VStack(alignment: .leading) {
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                Text(coin.name ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            // Sparkline chart
            if sparkline.isEmpty {
                Text("Loading chart...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                SparklineView(dataPoints: sparkline)
                    .frame(width: 80, height: 40)
            }
            
            // Current price & 24h change
            VStack(alignment: .trailing) {
                Text("$\(coin.current_price ?? 0, specifier: "%.2f")")
                    .font(.subheadline)
                Text("\(coin.price_change_percentage_24h ?? 0, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor((coin.price_change_percentage_24h ?? 0) >= 0 ? .green : .red)
            }
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - QuickActionButton
struct QuickActionButton: View {
    let label: String
    let systemIcon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                Text(label)
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
