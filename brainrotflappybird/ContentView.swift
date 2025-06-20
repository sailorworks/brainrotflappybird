// brainrotflappybird/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GameViewRepresentable()
            .ignoresSafeArea() // Makes the game view extend to the screen edges
            .statusBar(hidden: true) // Hides the status bar for a more immersive game feel
    }
}

// Optional: Keep previews if you use them
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
    
}//
//  ContentView.swift
//  brainrotflappybird
// 
//  Created by Sahil Prasad on 31/05/25.
//

