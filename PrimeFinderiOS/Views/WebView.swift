//
//  WebView.swift
//  PrimeFinder
//
//  Created by Terence  Ndabereye  on 17/06/2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var url: URL
    let webView: WKWebView
    init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.url = URL(string: "https://google.com")!
    }
    init(url: URL) {
        self.init()
        self.url = url
    }
    
    func makeUIView(context: Context) -> some UIView {
        webView.allowsLinkPreview = true
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let request = URLRequest(url: self.url)
        webView.loadFileURL(self.url, allowingReadAccessTo: self.url.deletingLastPathComponent())
//        webView.load(request)
    }
}

#Preview {
    WebView()
}
