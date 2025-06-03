// brainrotflappybird/GameViewRepresentable.swift
import SwiftUI
import SpriteKit // Not strictly needed here, but good for context

struct GameViewRepresentable: UIViewControllerRepresentable {

    typealias UIViewControllerType = GameViewController

    func makeUIViewController(context: Context) -> GameViewController {
        // Create an instance of our GameViewController
        let gameVC = GameViewController()
        return gameVC
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // This method is called if SwiftUI state changes that might affect the view controller.
        // For this simple game, we usually don't need to do anything here once it's set up.
        // If the GameViewController didn't present its scene (e.g., due to initial zero size),
        // this update might trigger its viewDidLayoutSubviews, which would then present it.
    }
}//
//  GameViewRepresentable.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 31/05/25.
//

