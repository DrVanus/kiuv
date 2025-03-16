//
//  SparklineView.swift
//  CRYPTOSAI
//
//  Displays a mini line chart using SwiftUI Charts (iOS 16+).
//

import SwiftUI
import Charts

struct SparklineView: View {
    let dataPoints: [Double]
    
    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Price", value)
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 40)
    }
}
