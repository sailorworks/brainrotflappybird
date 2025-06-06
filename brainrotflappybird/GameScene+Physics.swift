//
//  GameScene+Physics.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//
import SpriteKit

extension GameScene: SKPhysicsContactDelegate { // Explicitly state conformance again for clarity, though main class declares it
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !gameOver else { return } // Don't process new contacts if game is already over
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // Ensure firstBody is always the lower category bitmask (for consistent checks)
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Bird hits Pipe or Ground
        if firstBody.categoryBitMask == PhysicsCategory.bird &&
           (secondBody.categoryBitMask == PhysicsCategory.pipe || secondBody.categoryBitMask == PhysicsCategory.ground) {
            // Check if nodes still exist (they might be removed by other logic quickly)
            if firstBody.node != nil && secondBody.node != nil {
                 triggerGameOverSequence()
            }
        }
        // Bird passes through Score Node
        else if firstBody.categoryBitMask == PhysicsCategory.bird && secondBody.categoryBitMask == PhysicsCategory.scoreNode {
            if let scoreNodeToRemove = secondBody.node { // Make sure node exists
                score += 1
                scoreLabel.text = "\(score)"
                
                // Check if this is a new high score during gameplay
                checkForLiveHighScore()
                
                scoreNodeToRemove.removeFromParent() // Remove score node so it's only counted once
            }
        }
    }
    
    // MARK: - High Score During Gameplay
    func checkForLiveHighScore() {
        // Only trigger if we just beat the high score (not if we're already above it)
        if score == highScore + 1 && highScore > 0 {
            playHighScoreAchievedSound()
        }
    }
    
    func playHighScoreAchievedSound() {
        let highScoreSoundAction = SKAction.playSoundFileNamed(GameConstants.AudioFiles.highScoreAchievedSound, waitForCompletion: false)
        self.run(highScoreSoundAction)
        
        print("[HighScoreAchieved] Played high score sound at score: \(score)")
    }
}
