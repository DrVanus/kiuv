import Foundation
import Combine

extension BinanceService {
    /// Fetches K-line (candlestick) data from Binance and returns an array of ChartDataPoint
    static func fetchKlines(symbol: String,
                            interval: String,
                            limit: Int) -> AnyPublisher<[ChartDataPoint], Error> {
        // Construct the URL
        var components = URLComponents(string: "https://api.binance.com/api/v3/klines")!
        components.queryItems = [
            URLQueryItem(name: "symbol", value: symbol + "USDT"),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let request = URLRequest(url: components.url!)

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { data in
                // Parse JSON into nested arrays
                guard let json = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                    throw URLError(.cannotParseResponse)
                }
                // Map each entry to ChartDataPoint
                return json.compactMap { entry -> ChartDataPoint? in
                    guard entry.count >= 6,
                          let openTime = (entry[0] as? NSNumber)?.doubleValue,
                          let openStr   = entry[1] as? String,
                          let highStr   = entry[2] as? String,
                          let lowStr    = entry[3] as? String,
                          let closeStr  = entry[4] as? String,
                          let volStr    = entry[5] as? String,
                          let open      = Double(openStr),
                          let high      = Double(highStr),
                          let low       = Double(lowStr),
                          let close     = Double(closeStr),
                          let volume    = Double(volStr) else {
                        return nil
                    }
                    let date = Date(timeIntervalSince1970: openTime / 1000)
                    return ChartDataPoint(date: date, close: close)
                }
            }
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .eraseToAnyPublisher()
    }
}
