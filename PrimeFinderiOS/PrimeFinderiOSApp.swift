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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: DownloadTask.self)
                .onAppear {
//                    clearTmp()
                }
        }
    }
    private func clearTmp() {
        do {
            let fileManager = FileManager.default
            let tmpDir = fileManager.temporaryDirectory
            let attributes = try fileManager.attributesOfItem(atPath: tmpDir.path)
            let tmpDirSize = attributes[.size]
            
            let tmpFiles = try fileManager.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil)
            for file in tmpFiles {
                try fileManager.removeItem(at: file)
            }
            
            if let tmpDirSize = tmpDirSize as? Int64 {
                print("Removed \(tmpDirSize) bytes from tmp dircetory")
            }
        } catch {
            print("Failed to clear tmp: \(error)")
        }
    }
}
