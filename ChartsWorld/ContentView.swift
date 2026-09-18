//
//  ContentView.swift
//  ChartsWorld
//
//  Created by baby Enjhon on 9/15/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
    
        VStack {
            MainTabView()
             .padding()
        }
    }
}

#Preview {
    //EngineeringWaveCanvas()
    //AIAnomalDetectorCanvas()
    MainTabView()
}
