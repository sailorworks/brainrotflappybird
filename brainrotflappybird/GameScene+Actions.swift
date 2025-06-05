//
//  GameScene+Actions.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

import SpriteKit

extension GameScene {

    func startGroundScrolling() { // Renamed from moveGround
        let groundScrollSpeed = GameConstants.pipeSpeed * 60.0 // Points per second
        
        let groundSprites = ground.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name == GameConstants.NodeNames.ground }
        guard !groundSprites.isEmpty else {
            print("[GroundMovement] No ground sprites found to animate!")
            return
        }
        
        for groundSprite in groundSprites {
            // Calculate duration for one full scroll of a single ground sprite
            let moveDurationPerSprite = TimeInterval(groundSprite.size.width / groundScrollSpeed)
            
            let moveLeft = SKAction.moveBy(x: -groundSprite.size.width, y: 0, duration: moveDurationPerSprite)
            let resetPosition = SKAction.moveBy(x: groundSprite.size.width, y: 0, duration: 0) // Instant reset
            let sequence = SKAction.sequence([moveLeft, resetPosition])
            let repeatForever = SKAction.repeatForever(sequence)
            
            groundSprite.removeAction(forKey: "moveGroundAction") // Use a unique key
            groundSprite.run(repeatForever, withKey: "moveGroundAction")
        }
    }

    func stopGroundScrollingAction() { // Renamed from stopGroundScrolling
        for node in ground.children where node.name == GameConstants.NodeNames.ground {
            node.removeAction(forKey: "moveGroundAction")
        }
    }
}
