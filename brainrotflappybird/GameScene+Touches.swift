import SpriteKit

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        if characterSelectionActive {
            // Check if "TAP TO START GAME" button was tapped
            if let startGameButtonNode = childNode(withName: GameConstants.NodeNames.startGameButton),
               startGameButtonNode.contains(touchLocation) {
            
                proceedToGameStart() // This transitions from character selection to "Tap to Start" game screen
                return
            }
            
            // Check if a character preview was tapped
            for (index, previewBirdNode) in characterPreviewBirds.enumerated() {
                if previewBirdNode.contains(touchLocation) {
                    selectCharacter(at: index)
                    return
                }
            }
        } else { // Game is in "Ready", "Playing", or "Game Over" state
            if !gameStarted { // Either "Ready" state or "Game Over" state
                if gameOver {
                  
                    resetForNewGame() // This will take player back to character selection
                } else {
                    // "Ready" state (after character selection, "Tap to Start" is showing)
               
                    startGamePlay()
                    // flapBirdAction() // startGamePlay now includes an initial flap
                }
            } else if !gameOver { // Game is active and playing
                flapBirdAction()
            }
        }
    }
}
