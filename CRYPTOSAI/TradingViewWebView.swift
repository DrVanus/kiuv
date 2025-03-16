//
//  TradingViewWebView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// TradingViewWebView.swift
import SwiftUI
import WebKit

struct TradingViewWebView: UIViewRepresentable {
    let widgetURL: String = "https://s.tradingview.com/widgetembed/?frameElementId=tradingview_123&symbol=BTCUSD&interval=D&hidesidetoolbar=1&symboledit=1&saveimage=1&toolbarbg=f1f3f6&studies=[]&hideideas=1"
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: widgetURL) {
            uiView.load(URLRequest(url: url))
        }
    }
}