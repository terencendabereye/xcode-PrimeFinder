//
//  GroupedListView.swift
//  PrimeFinderiOS
//
//  Created by Terence  Ndabereye  on 21/06/2024.
//

import SwiftUI

struct GroupedListView: View {
    @State var even = (0..<10).map{$0*2}
    @State var odd = (0..<10).map{$0*2+1}
//    @State var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack() {
            List($even, id: \.self) { item in
                NavigationLink(value: item.wrappedValue) {
                    Text("Item \(item.wrappedValue)")
                }
            }
            .navigationDestination(for: Int.self, destination: { item in
                Text("This is number is \(item)")
            })
            .navigationTitle("Grouped List View")
//            .toolbar {
//                ToolbarItem{
//                    EditButton()
//                }
//            }
        }
    }
}

#Preview {
    GroupedListView()
}
