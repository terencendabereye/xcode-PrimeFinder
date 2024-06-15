//
//  ContentView.swift
//  PrimeFinder
//
//  Created by Terence  Ndabereye  on 19/05/2024.
//

import SwiftUI

struct ContentView: View {
    @State var count: Int = 0
    var body: some View {
        TabView {
            DownloadView()
                .tabItem { Label("Downloads", systemImage: "arrow.down") }
                PrimesView()
                    .tabItem { Label("Primes", systemImage: "divide") }
                    .badge(count)
        }
        .tabViewStyle(.automatic)
    }
}

#Preview {
    ContentView()
}
