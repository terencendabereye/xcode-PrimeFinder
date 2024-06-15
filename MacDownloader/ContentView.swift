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


#Preview {
    ContentView()
}
