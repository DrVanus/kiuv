import SwiftUI

struct CoinDetailView: View {
    let coin: MarketCoin
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text(coin.symbol.uppercased())
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text(coin.name)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "$%.2f", coin.price))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(String(format: "%+.2f%% (24h)", coin.dailyChange))
                        .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                    
                    // Chart placeholder
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 200)
                        .overlay(Text("Chart placeholder").foregroundColor(.gray))
                    
                    // etc...
                    Text("Volume (24h): \(shortVolume(coin.volume))")
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationBarTitle(coin.symbol.uppercased(), displayMode: .inline)
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
