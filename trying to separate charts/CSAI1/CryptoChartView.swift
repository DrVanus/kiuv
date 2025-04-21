//
//  CryptoChartView.swift
//  CSAI1
//

import SwiftUI
import Charts

// MARK: - ChartInterval
enum ChartInterval: String, CaseIterable {
    case oneMin     = "1m"
    case fiveMin    = "5m"
    case fifteenMin = "15m"
    case thirtyMin  = "30m"
    case oneHour    = "1H"
    case fourHour   = "4H"
    case oneDay     = "1D"
    case oneWeek    = "1W"
    case oneMonth   = "1M"
    case threeMonth = "3M"
    case oneYear    = "1Y"
    case threeYear  = "3Y"
    case all        = "ALL"

    var binanceInterval: String {
        switch self {
        case .oneMin:     return "1m"
        case .fiveMin:    return "5m"
        case .fifteenMin: return "15m"
        case .thirtyMin:  return "30m"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1d"
        case .oneWeek:    return "1w"
        case .oneMonth:   return "1M"
        case .threeMonth: return "1d"
        case .oneYear:    return "1d"
        case .threeYear:  return "1d"
        case .all:        return "1w"
        }
    }

    var binanceLimit: Int {
        switch self {
        case .oneMin:     return 60
        case .fiveMin:    return 48
        case .fifteenMin: return 24
        case .thirtyMin:  return 24
        case .oneHour:    return 48
        case .fourHour:   return 120
        case .oneDay:     return 60
        case .oneWeek:    return 52
        case .oneMonth:   return 12
        case .threeMonth: return 90
        case .oneYear:    return 365
        case .threeYear:  return 1095
        case .all:        return 999
        }
    }
}

// MARK: - ChartDataPoint
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let close: Double
}

// MARK: - ChartViewModel
class ChartViewModel: ObservableObject {
    @Published var dataPoints: [ChartDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 10
        return URLSession(configuration: cfg)
    }()

    private var symbol: String
    private var interval: ChartInterval

    init(symbol: String, interval: ChartInterval) {
        self.symbol = symbol.uppercased()
        self.interval = interval
        fetchBinanceData()
    }

    func update(symbol: String, interval: ChartInterval) {
        self.symbol = symbol.uppercased()
        self.interval = interval
        fetchBinanceData()
    }

    func fetchBinanceData() {
        let pair = symbol + "USDT"
        let urlStr = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=\(interval.binanceInterval)&limit=\(interval.binanceLimit)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL." }
            return
        }
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.dataPoints = []
        }
        session.dataTask(with: url) { data, _, err in
            DispatchQueue.main.async { self.isLoading = false }
            if let err = err {
                DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data." }
                return
            }
            self.parseKlines(data)
        }.resume()
    }

    private func parseKlines(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [[Any]], !json.isEmpty else {
                DispatchQueue.main.async { self.errorMessage = "Empty data." }
                return
            }
            let pts: [ChartDataPoint] = json.compactMap { entry in
                guard let t = entry[0] as? Double,
                      let c = entry[4] as? Double else { return nil }
                return ChartDataPoint(date: Date(timeIntervalSince1970: t/1000), close: c)
            }
            DispatchQueue.main.async { self.dataPoints = pts.sorted(by: { $0.date < $1.date }) }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - CryptoChartView
struct CryptoChartView: View {
    let symbol: String
    let interval: ChartInterval

    var body: some View {
        TradeCustomChart(symbol: symbol, interval: interval)
    }
}

// MARK: - TradeCustomChart
struct TradeCustomChart: View {
    let symbol: String
    let interval: ChartInterval

    @StateObject private var vm: ChartViewModel
    @State private var crosshair: ChartDataPoint? = nil
    @State private var showCrosshair: Bool = false

    init(symbol: String, interval: ChartInterval) {
        self.symbol = symbol
        self.interval = interval
        _vm = StateObject(wrappedValue: ChartViewModel(symbol: symbol, interval: interval))
    }

    var body: some View {
        ZStack {
            if vm.isLoading {
                ProgressView("Loading…").foregroundColor(.white)
            } else if let err = vm.errorMessage {
                errorView(err)
            } else if vm.dataPoints.isEmpty {
                Text("No data").foregroundColor(.gray)
            } else if #available(iOS 16, *) {
                chartContent.transition(.opacity)
            } else {
                Text("Requires iOS 16+").foregroundColor(.gray)
            }
        }
        .onChange(of: symbol) { _ in vm.update(symbol: symbol, interval: interval) }
        .onChange(of: interval) { _ in vm.update(symbol: symbol, interval: interval) }
    }

    @ViewBuilder
    @available(iOS 16, *)
    private var chartContent: some View {
        let pts = vm.dataPoints
        let closes = pts.map { $0.close }
        let minC = closes.min() ?? 0
        let maxC = closes.max() ?? 1
        let pad = (maxC - minC) * 0.03
        let lower = max(0, minC)
        let upper = maxC + pad
        let first = pts.first!.date
        let last  = pts.last!.date

        Chart {
            ForEach(pts) { p in
                LineMark(x: .value("Time", p.date), y: .value("Close", p.close))
                    .foregroundStyle(.yellow)
                AreaMark(x: .value("Time", p.date), yStart: .value("Close", lower), yEnd: .value("Close", p.close))
                    .foregroundStyle(
                        LinearGradient(gradient: Gradient(colors: [.yellow.opacity(0.3), .yellow.opacity(0.15), .clear]),
                                       startPoint: .top, endPoint: .bottom))
            }
            if showCrosshair, let c = crosshair {
                RuleMark(x: .value("Time", c.date)).foregroundStyle(.white.opacity(0.7))
                RuleMark(y: .value("Price", c.close)).foregroundStyle(.white.opacity(0.7))
                PointMark(x: .value("Time", c.date), y: .value("Close", c.close))
                    .symbolSize(80).foregroundStyle(.white)
                    .annotation(position: .top) {
                        VStack {
                            Text(c.date, format: .dateTime.hour().minute()).font(.caption2).foregroundColor(.white)
                            Text(formatWithCommas(c.close)).font(.caption2).foregroundColor(.white)
                        }
                        .padding(6).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.8)))
                    }
            }
        }
        .chartYScale(domain: lower...upper)
        .chartXScale(domain: first...last)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { g in
                                    showCrosshair = true
                                    let x = g.location.x - geo[proxy.plotAreaFrame].origin.x
                                    if let date: Date = proxy.value(atX: x),
                                       let c = findClosest(date: date, in: pts) {
                                        crosshair = c
                                    }
                                }
                                .onEnded { _ in showCrosshair = false })
            }
        }
        .chartPlotStyle { $0.background(Color.black.opacity(0.05)) }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Text("Error loading").foregroundColor(.red).font(.headline)
            Text(msg).foregroundColor(.gray).font(.caption)
            Button("Retry") { vm.fetchBinanceData() }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.yellow).cornerRadius(8)
        }.padding()
    }

    private func formatWithCommas(_ v: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = v < 1 ? 2 : 2
        fmt.maximumFractionDigits = v < 1 ? 8 : 2
        return "$" + (fmt.string(from: NSNumber(value: v)) ?? "0")
    }

    private func findClosest(date: Date, in pts: [ChartDataPoint]) -> ChartDataPoint? {
        guard !pts.isEmpty else { return nil }
        var best = pts[0]; var minD = abs(best.date.timeIntervalSince(date))
        for p in pts {
            let d = abs(p.date.timeIntervalSince(date))
            if d < minD { best = p; minD = d }
        }
        return best
    }
}
