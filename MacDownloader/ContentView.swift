//
//  ContentView.swift
//  MacDownloader
//
//  Created by Terence  Ndabereye  on 13/06/2024.
//

import SwiftUI

struct ContentView: View {
    @State var showImage: Bool = true
    @State var isOnline: Bool = true
    var body: some View {
        ZStack {
//            MeshGradient (width: 3, height: 3, points: [
//                [0.0,0.0],[0.5,0.0],[1.0,0.0],
//                [0.0,0.5],[0.5,0.5],[1.0,0.5],
//                [0.0,1.0],[0.5,1.0],[1.0,1.0]
//            ], colors: [
//                .black, .black, .black,
//                .blue, .blue, .blue,
//                .green, .green, .green
//            ])
            VStack {
                Toggle("show", isOn: $showImage)
                if showImage {
                    Image(systemName:  isOnline ? "cable.connector" : "cable.connector.slash")
                        .font(.largeTitle)
                        .transition(.scale)
                        .contentTransition(.symbolEffect(.automatic))
                        .symbolEffect(.wiggle.up)
                        .onTapGesture {
                            isOnline.toggle()
                        }
                } else {
                    Image(systemName:  isOnline ? "cable.connector" : "cable.connector.slash")
                        .font(.largeTitle)
                        .transition(.scale)
                        .contentTransition(.symbolEffect(.automatic))
                        .symbolEffect(.wiggle.up)
                        .onTapGesture {
                            isOnline.toggle()
                        }
                        .hidden()
                }
                
                Text("Hello!\nMy name is \nTerence \nNdabereye")
                    
//                List {
//                    ForEach(1..<5) {item in
//                        Text("Number: \(item)")
//                    }
//                }
                
            }
            .padding()
        }
    }
}


#Preview {
    ContentView()
}

//struct AppearanceEffectRenderer: TextRenderer, Animatable {
//    var elapsedTime: TimeInterval
//    var elementDuration: TimeInterval
//    var totalDuration: TimeInterval
//    
//    var animatableData: Double {
//        get {elapsedTime}
//        set {elapsedTime = newValue}
//    }
//    
//    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
//        let delay = elementDelay(count: layout.count)
//        
//        for (i, line) in layout.enumerated() {
//            let timeOffset = TimeInterval(i) * delay
//            let elementTime = max(0, min(elapsedTime - timeOffset, elementDuration))
//            
//            var copy = context
//            draw(line, at: elementTime, in: &copy)
//        }
//    }
//    
//    private func elementDelay(count: Int) -> TimeInterval {
//        0
//    }
//    
//    
//}
