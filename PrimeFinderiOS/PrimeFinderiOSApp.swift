//
//  PrimeFinderiOSApp.swift
//  PrimeFinderiOS
//
//  Created by Terence  Ndabereye  on 28/05/2024.
//

import SwiftUI
import SwiftData

@main
struct PrimeFinderiOSApp: App {
    var body: some Scene {
        
        #if os(macOS)
        MenuBarExtra("My menu bar"){
            Text("sda")
        }
        #endif
        
        WindowGroup {
            ContentView()
//                .modelContainer(for: [DownloadTask.self])
        }
    }
}
