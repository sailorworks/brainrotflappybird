//
//  GameScene+Update.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

import SpriteKit

extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Bird rotation based on velocity
        if gameStarted && !gameOver && bird != nil {
            if let dy = bird.physicsBody?.velocity.dy {
                let rotation = max(min(dy * 0.002, 0.5), -0.8) // Clamp rotation
                bird.zRotation = rotation
            }
        }
        
        // Check if bird fell off screen (below visible ground or significantly off bottom)
        if bird != nil && !gameOver {
            let groundLevel = (ground?.children.first as? SKSpriteNode)?.frame.minY ?? 0
            // If bird is below the visual ground OR significantly off-screen if ground isn't defined/found
            if bird.position.y < groundLevel || bird.position.y < -self.frame.size.height / 2 {
                 // Check if it's below the *actual* ground physics body might be more accurate if ground sprite is tall
                 // For simplicity, if it's clearly off screen, game over.
                 if bird.position.y < (groundLevel - bird.size.height) { // Ensure it's fully below ground
                     triggerGameOverSequence()
                 }
            }
        }
    }
}
