//
//  GameScene+Nodes.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

import SpriteKit

extension GameScene {

    @objc func spawnPipePairAction() { // Renamed from spawnPipePair
        guard gameStarted && !gameOver else { return }

        guard let bottomPipeTexture = SKTexture(optionalImageNamed: GameConstants.ImageNames.pipe),
              let topPipeTexture = SKTexture(optionalImageNamed: GameConstants.ImageNames.pipeInverted) else {
            print("[PipeSpawn] ERROR: Pipe texture(s) not found. Skipping spawn.")
            return
        }
        bottomPipeTexture.filteringMode = .nearest
        topPipeTexture.filteringMode = .nearest

        let pipeImageWidth = bottomPipeTexture.size().width
        let groundHeight = (ground.children.first as? SKSpriteNode)?.size.height ?? 80.0

        let minGapBottomY = groundHeight + GameConstants.verticalPaddingForPipes + 50.0
        let maxGapBottomY = self.frame.height - GameConstants.verticalPaddingForPipes - 50.0 - GameConstants.pipeGap
        
        guard maxGapBottomY > minGapBottomY else {
            print("[PipeSpawn] CRITICAL: Not enough vertical space. MinY: \(minGapBottomY), MaxY: \(maxGapBottomY)")
            return
        }
        let gapBottomY = CGFloat.random(in: minGapBottomY...maxGapBottomY)
        let gapTopY = gapBottomY + GameConstants.pipeGap

        let spawnXPosition = self.frame.maxX + pipeImageWidth / 2
        var nodesToAnimate: [SKNode] = []

        // Bottom Pipe
        let bottomPipeHeight = gapBottomY - groundHeight
        guard bottomPipeHeight > 0 else { return }
        let bottomPipe = SKSpriteNode(texture: bottomPipeTexture)
        bottomPipe.name = GameConstants.NodeNames.pipe
        bottomPipe.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bottomPipe.size = CGSize(width: pipeImageWidth, height: bottomPipeHeight)
        bottomPipe.position = CGPoint(x: spawnXPosition, y: groundHeight)
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size, center: CGPoint(x: 0, y: bottomPipe.size.height / 2))
        configurePipePhysics(for: bottomPipe.physicsBody)
        bottomPipe.zPosition = GameConstants.ZPositions.pipes
        addChild(bottomPipe)
        nodesToAnimate.append(bottomPipe)

        // Top Pipe
        let topPipeHeight = self.frame.height - gapTopY
        guard topPipeHeight > 0 else { return }
        let topPipe = SKSpriteNode(texture: topPipeTexture)
        topPipe.name = GameConstants.NodeNames.pipe
        topPipe.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        topPipe.size = CGSize(width: pipeImageWidth, height: topPipeHeight)
        topPipe.position = CGPoint(x: spawnXPosition, y: self.frame.height)
        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size, center: CGPoint(x: 0, y: -topPipe.size.height / 2))
        configurePipePhysics(for: topPipe.physicsBody)
        topPipe.zPosition = GameConstants.ZPositions.pipes
        addChild(topPipe)
        nodesToAnimate.append(topPipe)
        
        // Score Node
        let scoreNodeInstance = SKNode() // Renamed from scoreNode to avoid conflict with property
        scoreNodeInstance.name = GameConstants.NodeNames.scoreNode
        scoreNodeInstance.position = CGPoint(x: spawnXPosition, y: (gapBottomY + gapTopY) / 2)
        scoreNodeInstance.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: GameConstants.pipeGap))
        scoreNodeInstance.physicsBody?.isDynamic = false
        scoreNodeInstance.physicsBody?.categoryBitMask = PhysicsCategory.scoreNode
        scoreNodeInstance.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        scoreNodeInstance.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(scoreNodeInstance)
        nodesToAnimate.append(scoreNodeInstance)

        // Actions
        let moveDistance = self.frame.width + pipeImageWidth
        let pointsPerSecondSpeed = GameConstants.pipeSpeed * 60.0
        let moveDuration = TimeInterval(moveDistance / pointsPerSecondSpeed)
        let moveAction = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])

        for node in nodesToAnimate {
            node.run(sequence)
        }
    }

    private func configurePipePhysics(for body: SKPhysicsBody?) {
        body?.isDynamic = false
        body?.categoryBitMask = PhysicsCategory.pipe
        body?.contactTestBitMask = PhysicsCategory.bird
        body?.collisionBitMask = PhysicsCategory.bird
    }
}
