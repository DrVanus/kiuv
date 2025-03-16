//
//  NewsWebView.swift
//  CRYPTOSAI
//
//  Created by DM on 3/16/25.
//


// NewsWebView.swift
import SwiftUI
import WebKit

struct NewsWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            uiView.load(URLRequest(url: url))
        }
    }
}