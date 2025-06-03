// brainrotflappybird/GameViewController.swift
import UIKit
import SpriteKit
import GameplayKit // Keep this if GameScene uses it, though not strictly needed by GVC itself

class GameViewController: UIViewController {

    private var scenePresented = false

    override func loadView() {
        // Create the SKView programmatically that will be this controller's main view
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // viewDidLoad is called after loadView and the view hierarchy is set up.
        // The view's bounds might not be finalized yet if using auto layout or SwiftUI.
        // We'll try to present the scene here, but also have a fallback in viewDidLayoutSubviews.
        presentSceneIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // This is called after the view's bounds are finalized by the layout system (SwiftUI).
        // This is a more reliable place to get the correct view size.
        presentSceneIfNeeded()
    }

    private func presentSceneIfNeeded() {
        // Only proceed if the scene hasn't been presented and the view is an SKView
        guard !scenePresented, let skView = self.view as? SKView else {
            return
        }

        // Ensure the view has a valid size before creating the scene
        if skView.bounds.size.width > 0 && skView.bounds.size.height > 0 {
            print("GameViewController: Presenting scene with size \(skView.bounds.size)")

            let scene = GameScene(size: skView.bounds.size)
            scene.scaleMode = .aspectFill // Or .resizeFill

            skView.presentScene(scene)

            // Debugging options
            skView.ignoresSiblingOrder = true
            // skView.showsFPS = true
            // skView.showsNodeCount = true
            // skView.showsPhysics = true // Very useful for debugging physics

            scenePresented = true // Mark as presented
        } else {
            print("GameViewController: View size is not yet valid, deferring scene presentation. Current bounds: \(skView.bounds)")
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Flappy Bird is typically portrait
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
