//
//  GameScene+GameState.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

import SpriteKit

extension GameScene {

    // --- High Score Logic ---
    func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: GameConstants.UserDefaultsKeys.highScore)
        print("[HighScore] Loaded: \(highScore)")
    }

    func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: GameConstants.UserDefaultsKeys.highScore)
        // UserDefaults.standard.synchronize() // No longer necessary in modern iOS/macOS
        print("[HighScore] Saved: \(highScore)")
    }

    func checkAndUpdateHighScore() {
        if score > highScore {
            highScore = score
            isNewHighScore = true
            saveHighScore()
            print("[HighScore] NEW HIGH SCORE: \(highScore)")
        } else {
            isNewHighScore = false
        }
    }

    // --- Game Flow ---
    func startGamePlay() { // Renamed from startGame to avoid conflict with node name
        guard bird != nil else {
            print("Error: Bird node is nil. Cannot start game.")
            return
        }
        
        gameStarted = true
        gameOver = false
        tapToStartLabel.isHidden = true
        bird.isHidden = false
        
        bird.physicsBody?.affectedByGravity = true
        bird.physicsBody?.velocity = CGVector.zero
        
        resetGroundNodePositions()
        
        pipeSpawnTimer?.invalidate()
        pipeSpawnTimer = Timer.scheduledTimer(timeInterval: GameConstants.pipeSpawnInterval, target: self, selector: #selector(spawnPipePairAction), userInfo: nil, repeats: true)
        print("[GameLogic] Game started, pipeSpawnTimer active.")
        
        startGroundScrolling()
        flapBirdAction() // Initial flap to get going
    }
    
    func flapBirdAction() { // Renamed from flapBird
        guard gameStarted && !gameOver, bird != nil else { return }
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: GameConstants.birdFlapForce))
        let flapUpAction = SKAction.rotate(toAngle: 0.3, duration: 0.1)
        bird.run(flapUpAction)
    }

    func triggerGameOverSequence() { // Renamed from triggerGameOver
        guard !gameOver else { return }
        gameOver = true
        gameStarted = false
        
        checkAndUpdateHighScore()
        
        bird?.physicsBody?.affectedByGravity = false
        bird?.physicsBody?.velocity = CGVector.zero
        
        pipeSpawnTimer?.invalidate()
        pipeSpawnTimer = nil
        
        self.enumerateChildNodes(withName: "//*") { (node, _) in
            if node.name == GameConstants.NodeNames.pipe || node.name == GameConstants.NodeNames.scoreNode {
                node.removeAllActions()
            }
        }
        
        stopGroundScrollingAction()
        
        // Game Over UI
        let gameOverLabelNode = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        // Font check...
        gameOverLabelNode.text = "Game Over"
        gameOverLabelNode.name = GameConstants.NodeNames.gameOverLabel
        gameOverLabelNode.fontSize = 50; gameOverLabelNode.fontColor = SKColor.red
        gameOverLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 80)
        gameOverLabelNode.zPosition = GameConstants.ZPositions.gameOverUI
        addChild(gameOverLabelNode)
        
        let finalScoreLabelNode = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        // Font check...
        finalScoreLabelNode.text = "Score: \(score)"
        finalScoreLabelNode.name = GameConstants.NodeNames.finalScoreLabel
        finalScoreLabelNode.fontSize = 35; finalScoreLabelNode.fontColor = SKColor.white
        finalScoreLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 20)
        finalScoreLabelNode.zPosition = GameConstants.ZPositions.gameOverUI
        addChild(finalScoreLabelNode)
        
        let gameOverHighScoreDisplay = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        // Font check...
        gameOverHighScoreDisplay.text = "Best: \(highScore)"
        gameOverHighScoreDisplay.name = GameConstants.NodeNames.gameOverHighScoreLabel
        gameOverHighScoreDisplay.fontSize = 30; gameOverHighScoreDisplay.fontColor = SKColor.yellow
        gameOverHighScoreDisplay.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 20)
        gameOverHighScoreDisplay.zPosition = GameConstants.ZPositions.gameOverUI
        addChild(gameOverHighScoreDisplay)
        
        if isNewHighScore {
            newHighScoreLabel = SKLabelNode(fontNamed: GameConstants.FontNames.main)
            // Font check...
            newHighScoreLabel.text = "NEW HIGH SCORE!"
            newHighScoreLabel.name = GameConstants.NodeNames.newHighScoreLabel
            newHighScoreLabel.fontSize = 25; newHighScoreLabel.fontColor = SKColor.green
            newHighScoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 60)
            newHighScoreLabel.zPosition = GameConstants.ZPositions.gameOverUI
            addChild(newHighScoreLabel)
            let pulse = SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.5), SKAction.scale(to: 1.0, duration: 0.5)])
            newHighScoreLabel.run(SKAction.repeatForever(pulse))
        }
        
        tapToStartLabel.text = "Tap to Restart"
        tapToStartLabel.isHidden = false
        tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 100) // Lower position for restart
    }

    func resetForNewGame() { // Renamed from resetGame
        stopCharacterAudio()
        
        removeChildren(in: self.children.filter {
            $0.name == GameConstants.NodeNames.pipe ||
            $0.name == GameConstants.NodeNames.scoreNode ||
            $0.name == GameConstants.NodeNames.gameOverLabel ||
            $0.name == GameConstants.NodeNames.finalScoreLabel ||
            $0.name == GameConstants.NodeNames.gameOverHighScoreLabel ||
            $0.name == GameConstants.NodeNames.newHighScoreLabel
        })
        newHighScoreLabel?.removeFromParent() // Ensure it's removed if it was added
        
        resetGroundNodePositions()
        isNewHighScore = false
        
        // Go back to character selection
        setupCharacterSelectionScreen()
    }

    func resetGroundNodePositions() { // Renamed from resetGroundPositions
        stopGroundScrollingAction()
        
        var index = 0
        for node in ground.children where node.name == GameConstants.NodeNames.ground {
            guard let groundSprite = node as? SKSpriteNode else { continue }
            groundSprite.position = CGPoint(x: CGFloat(index) * groundSprite.size.width, y: 0)
            index += 1
        }
    }
}
