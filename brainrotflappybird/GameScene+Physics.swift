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
                scoreNodeToRemove.removeFromParent() // Remove score node so it's only counted once
            }
        }
    }
}
