import SwiftUI
import Combine
// import Foundation


// MARK: - Tile Model
struct HeatMapTile: Identifiable, Equatable, Decodable {
    let id = UUID()
    let symbol: String
    let pctChange: Double
    let marketCap: Double

    private enum CodingKeys: String, CodingKey {
        case symbol
        case pctChange = "price_change_percentage_24h"
        case marketCap = "market_cap"
    }
}

// MARK: - Helper Functions
/// Maps -10%…+10% change to red–green hue
private func color(for pct: Double) -> Color {
    let capped = min(max(pct, -10), 10)
    let t = (capped + 10) / 20   // 0…1
    return Color(hue: 0.33 * t, saturation: 0.8, brightness: 0.9)
}

/// Linear interpolation helper
private func interp(_ a: Double, _ b: Double, fraction f: Double) -> Double {
    return a + (b - a) * f
}

/// Maps a pct change to a red→amber→green gradient based on dynamic maxAbsPct
private func dynamicColor(for pct: Double, bound: Double) -> Color {
    // Define visually balanced color stops
    let redRGB   = (r: 0.839, g: 0.306, b: 0.306) // #D64E4E
    let amberRGB = (r: 1.000, g: 0.827, b: 0.000) // #FFD366
    let greenRGB = (r: 0.307, g: 0.788, b: 0.416) // #4EC96A

    // Clamp and normalize
    let capped = min(max(pct, -bound), bound)
    let t = (capped + bound) / (2 * bound) // 0…1

    if t < 0.5 {
        let f = t / 0.5
        return Color(
            red:   interp(redRGB.r,   amberRGB.r, fraction: f),
            green: interp(redRGB.g,   amberRGB.g, fraction: f),
            blue:  interp(redRGB.b,   amberRGB.b, fraction: f)
        )
    } else {
        let f = (t - 0.5) / 0.5
        return Color(
            red:   interp(amberRGB.r, greenRGB.r, fraction: f),
            green: interp(amberRGB.g, greenRGB.g, fraction: f),
            blue:  interp(amberRGB.b, greenRGB.b, fraction: f)
        )
    }
}

/// Squarified treemap layout to minimize aspect ratio
private func squarify(
    items: [HeatMapTile],
    weights: [Double],
    rect: CGRect
) -> [CGRect] {
    var rects: [CGRect] = []
    // Recursively pack rows
    func layout(_ entries: [(HeatMapTile, Double)], in r: CGRect) {
        // decide orientation based on current rect shape
        let horizontal = r.width < r.height
        guard !entries.isEmpty else { return }
        var row: [(HeatMapTile, Double)] = []
        var remaining = entries

        func worstRatio(_ row: [(HeatMapTile, Double)], in r: CGRect) -> CGFloat {
            let total = row.reduce(0) { $0 + $1.1 }
            let side = horizontal ? r.width : r.height
            return row.map { (_, w) in
                let frac = CGFloat(w / total)
                let length = (horizontal ? r.height : r.width) * frac
                return max(side / length, length / side)
            }.max() ?? .infinity
        }

        while !remaining.isEmpty {
            let next = remaining.removeFirst()
            let newRow = row + [next]
            if row.isEmpty || worstRatio(newRow, in: r) <= worstRatio(row, in: r) {
                row = newRow
            } else {
                remaining.insert(next, at: 0)
                break
            }
        }

        // Layout the finalized row
        let totalWeight = row.reduce(0) { $0 + $1.1 }
        var offset: CGFloat = 0
        for (tile, w) in row {
            let frac = totalWeight > 0 ? w / totalWeight : 0
            let slice: CGRect
            if horizontal {
                let height = r.height * CGFloat(frac)
                slice = CGRect(x: r.minX, y: r.minY + offset, width: r.width, height: height)
                offset += height
            } else {
                let width = r.width * CGFloat(frac)
                slice = CGRect(x: r.minX + offset, y: r.minY, width: width, height: r.height)
                offset += width
            }
            rects.append(slice)
        }

        // Compute leftover rect and recurse
        let usedFrac = row.reduce(0) { $0 + $1.1 } / entries.reduce(0) { $0 + $1.1 }
        let leftover: CGRect
        if horizontal {
            let usedHeight = r.height * CGFloat(usedFrac)
            leftover = CGRect(x: r.minX, y: r.minY + usedHeight, width: r.width, height: r.height - usedHeight)
        } else {
            let usedWidth = r.width * CGFloat(usedFrac)
            leftover = CGRect(x: r.minX + usedWidth, y: r.minY, width: r.width - usedWidth, height: r.height)
        }
        layout(remaining, in: leftover)
    }

    layout(Array(zip(items, weights)), in: rect)
    return rects
}

// MARK: - Treemap View
struct TreemapView: View {
    let tiles: [HeatMapTile]
    /// Spacing between tiles
    var tileSpacing: CGFloat = 2
    /// Minimum area to show labels
    var labelThreshold: CGFloat = 50
    /// Animate layout updates
    var animationDuration: Double = 0.5
    /// Show legend below the map
    var showLegend: Bool = true

    /// Effective color bound: ±10% or largest observed change, whichever is greater
    private var colorBound: Double {
        let maxChange = tiles.map { abs($0.pctChange) }.max() ?? 0
        return max(10, maxChange)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // DEBUG: show count of display tiles
            // Text("Display Tiles: \(displayTiles.count)")
            //     .font(.caption)
            //     .foregroundColor(.white)
            //     .padding(.leading, 8)
            GeometryReader { geo in
                let maxTiles = max(1, Int(geo.size.width / 80)) // adaptive top count based on width
                Canvas { context, size in
                    // 1. Select top N tiles by market cap, and group the rest as "Others"
                    let sortedAll = tiles.sorted { $0.marketCap > $1.marketCap }
                    // Show up to maxTiles largest coins, then group all others
                    let topCount = min(maxTiles, sortedAll.count)
                    let topTiles = Array(sortedAll.prefix(topCount))
                    let smallTiles = sortedAll.dropFirst(topCount)

                    var displayTiles: [HeatMapTile] = topTiles
                    if !smallTiles.isEmpty {
                        let othersCap = smallTiles.reduce(0) { $0 + $1.marketCap }
                        let weightedSum = smallTiles.reduce(0) { $0 + $1.pctChange * $1.marketCap }
                        let othersPct = othersCap > 0 ? weightedSum / othersCap : 0
                        displayTiles.append(HeatMapTile(symbol: "Others", pctChange: othersPct, marketCap: othersCap))
                    }

                    // Use squarified treemap layout
                    let startHorizontal = size.width > size.height
                    let rects = squarify(
                        items: displayTiles,
                        weights: displayTiles.map { $0.marketCap },
                        rect: CGRect(origin: .zero, size: size)
                    )
                    for (tile, rect) in zip(displayTiles, rects) {
                        let insetRect = rect.insetBy(dx: tileSpacing/2, dy: tileSpacing/2)
                        // Draw rounded tile background
                        let roundedPath = Path(roundedRect: insetRect, cornerRadius: 4)
                        context.fill(roundedPath, with: .color(dynamicColor(for: tile.pctChange, bound: colorBound)))
                        // Draw subtle border
                        context.stroke(roundedPath, with: .color(.white.opacity(0.2)), lineWidth: 1)
                        // label if area large enough and roughly square
                        let area = insetRect.width * insetRect.height
                        let aspectRatio = min(insetRect.width, insetRect.height) / max(insetRect.width, insetRect.height)
                        if area > labelThreshold && aspectRatio > 0.5 {
                            var attr = AttributedString("\(tile.symbol)\n\(String(format: "%+.1f%%", tile.pctChange))")
                            attr.foregroundColor = .white
                            attr.font = .system(size: min(insetRect.width, insetRect.height) * 0.2, weight: .bold)
                            let text = Text(attr)
                            context.draw(text, at: CGPoint(x: insetRect.midX, y: insetRect.midY))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: tiles)
            }
            if showLegend {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(String(format: "-%.0f%%", colorBound))
                            .font(.caption)
                            .foregroundColor(.white)
                        GeometryReader { geo in
                            let gradient = LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: dynamicColor(for: -colorBound, bound: colorBound), location: 0.0),
                                    .init(color: dynamicColor(for: 0, bound: colorBound), location: 0.5),
                                    .init(color: dynamicColor(for: colorBound, bound: colorBound), location: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(gradient)
                                    .frame(height: 6)
                                // Tick marks at 0%, 50%, 100%
                                Group {
                                    Rectangle()
                                        .frame(width: 1, height: 10)
                                        .foregroundColor(Color.white.opacity(0.7))
                                        .position(x: 0, y: 5)
                                    Rectangle()
                                        .frame(width: 1, height: 10)
                                        .foregroundColor(Color.white.opacity(0.7))
                                        .position(x: geo.size.width * 0.5, y: 5)
                                    Rectangle()
                                        .frame(width: 1, height: 10)
                                        .foregroundColor(Color.white.opacity(0.7))
                                        .position(x: geo.size.width, y: 5)
                                }
                            }
                        }
                        .frame(height: 16)
                        Text(String(format: "+%.0f%%", colorBound))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 0) {
                        Text("Fear")
                            .frame(maxWidth: .infinity)
                            .font(.caption2)
                            .foregroundColor(dynamicColor(for: -colorBound, bound: colorBound))
                        Text("Neutral")
                            .frame(maxWidth: .infinity)
                            .font(.caption2)
                            .foregroundColor(dynamicColor(for: 0, bound: colorBound))
                        Text("Greed")
                            .frame(maxWidth: .infinity)
                            .font(.caption2)
                            .foregroundColor(dynamicColor(for: colorBound, bound: colorBound))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Heat Map ViewModel

class HeatMapViewModel: ObservableObject {
    @Published var tiles: [HeatMapTile] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchHeatMapData()
        // Refresh every 60 seconds
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchHeatMapData() }
            .store(in: &cancellables)
    }

    func fetchHeatMapData() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .retry(2) // retry up to 2 times on failure
            .map(\.data)
            .decode(type: [HeatMapTile].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("HeatMap fetch error:", error)
                }
            } receiveValue: { [weak self] tiles in
                print("HeatMap fetched:", tiles.count)
                self?.tiles = tiles
            }
            .store(in: &cancellables)
    }
}
