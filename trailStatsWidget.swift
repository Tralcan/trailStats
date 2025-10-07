//
//  ContentView.swift
//  ExampleApp
//
//  Created by Developer on 2023-04-10.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive: Bool = false
    @State private var counter: Int = 0

    var body: some View {
        VStack {
            Text("Counter: \(counter)")
                .font(.largeTitle)
                .padding()

            Button(action: {
                self.counter += 1
            }) {
                Text("Increment")
            }
            .padding()

            Toggle(isOn: $isActive) {
                Text("Active State")
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
