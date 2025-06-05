//
//  GameScene+CharacterSelection.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

import SpriteKit
import AVFoundation

extension GameScene {

    func loadCharacterTextures() {
        characterTextures.removeAll()
        for name in GameConstants.ImageNames.characterBirds {
            if let texture = SKTexture(optionalImageNamed: name) {
                texture.filteringMode = .nearest
                characterTextures.append(texture)
                print("[CharacterLoad] Loaded texture: \(name)")
            } else {
                print("[CharacterLoad] WARNING: Could not load \(name), using placeholder.")
                characterTextures.append(SKTexture()) // Placeholder
            }
        }
    }

    func setupCharacterSelectionScreen() {
        characterSelectionActive = true
        loadCharacterTextures()
        
        // Hide game elements not relevant to character selection
        tapToStartLabel.isHidden = true
        scoreLabel.isHidden = true
        highScoreLabel.isHidden = true // Hide during character selection
        bird?.isHidden = true // The placeholder bird

        // Create selection instruction label
        characterSelectionInstructionLabel = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        if UIFont(name: GameConstants.FontNames.main, size: 1) == nil {
            characterSelectionInstructionLabel.fontName = GameConstants.FontNames.fallback
        }
        characterSelectionInstructionLabel.text = "Tap on a character to select"
        characterSelectionInstructionLabel.fontSize = 20
        characterSelectionInstructionLabel.fontColor = SKColor.white
        characterSelectionInstructionLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 100)
        characterSelectionInstructionLabel.zPosition = GameConstants.ZPositions.characterSelectionLabel
        characterSelectionInstructionLabel.name = GameConstants.NodeNames.characterSelectionUI
        addChild(characterSelectionInstructionLabel)
        
        // Create character preview birds
        characterPreviewBirds.removeAllChildren() // Clear existing previews if any
        let spacing: CGFloat = 120
        let startX = self.frame.midX - spacing // Center the group of 3 birds
        
        for i in 0..<characterTextures.count {
            let previewBird: SKSpriteNode
            let texture = characterTextures[i]
            
            if texture.size().width > 0 && texture.size().height > 0 {
                previewBird = SKSpriteNode(texture: texture)
                let desiredHeight: CGFloat = 50.0
                let aspectRatio = texture.size().width / texture.size().height
                previewBird.size = CGSize(width: desiredHeight * aspectRatio, height: desiredHeight)
            } else {
                let colors: [SKColor] = [.orange, .red, .blue]
                previewBird = SKSpriteNode(color: colors[i % colors.count], size: CGSize(width: 40 * 1.2, height: 28 * 1.2))
            }
            
            previewBird.position = CGPoint(x: startX + (spacing * CGFloat(i)), y: self.frame.midY)
            previewBird.zPosition = GameConstants.ZPositions.characterPreview
            previewBird.name = "\(GameConstants.NodeNames.characterPreviewPrefix)\(i)"
            
            let border = SKShapeNode(rect: CGRect(x: -previewBird.size.width/2 - 5,
                                                y: -previewBird.size.height/2 - 5,
                                                width: previewBird.size.width + 10,
                                                height: previewBird.size.height + 10))
            border.strokeColor = i == selectedCharacterIndex ? SKColor.yellow : SKColor.clear
            border.lineWidth = 3
            border.name = GameConstants.NodeNames.selectionBorder
            previewBird.addChild(border)
            
            let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 1.0)
            let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 1.0)
            let floatSequence = SKAction.sequence([floatUp, floatDown])
            previewBird.run(SKAction.repeatForever(floatSequence))
            
            characterPreviewBirds.append(previewBird)
            addChild(previewBird)
        }
        
        // Add "Start Game" button
        let startGameLabelNode = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        if UIFont(name: GameConstants.FontNames.main, size: 1) == nil {
            startGameLabelNode.fontName = GameConstants.FontNames.fallback
        }
        startGameLabelNode.text = "TAP TO START GAME"
        startGameLabelNode.fontSize = 25
        startGameLabelNode.fontColor = SKColor.green
        startGameLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 150)
        startGameLabelNode.zPosition = GameConstants.ZPositions.startGameButton
        startGameLabelNode.name = GameConstants.NodeNames.startGameButton
        addChild(startGameLabelNode)
        
        print("[CharacterSelection] Screen setup complete.")
    }

    func selectCharacter(at index: Int) {
        guard index >= 0 && index < characterPreviewBirds.count else { return }
        
        selectedCharacterIndex = index
        playCharacterSelectionAudio(for: index)
        
        for (i, previewBird) in characterPreviewBirds.enumerated() {
            if let border = previewBird.childNode(withName: GameConstants.NodeNames.selectionBorder) as? SKShapeNode {
                border.strokeColor = i == selectedCharacterIndex ? SKColor.yellow : SKColor.clear
            }
        }
        print("[CharacterSelection] Selected character \(index + 1)")
    }
    
    func updateBirdToSelectedCharacter() {
        guard selectedCharacterIndex < characterTextures.count else {
            print("[CharacterUpdate] Invalid character index, bird not updated.")
            return
        }
        
        let selectedTexture = characterTextures[selectedCharacterIndex]
        
        bird?.removeFromParent() // Remove existing bird node (placeholder or previous game's)
        
        if selectedTexture.size().width > 0 && selectedTexture.size().height > 0 {
            bird = SKSpriteNode(texture: selectedTexture)
            // Scale bird slightly for gameplay, adjust as needed
            bird.size = CGSize(width: selectedTexture.size().width * 0.8,
                              height: selectedTexture.size().height * 0.8)
            print("[CharacterUpdate] Updated bird with character \(selectedCharacterIndex + 1)")
        } else {
            let colors: [SKColor] = [.orange, .red, .blue]
            bird = SKSpriteNode(color: colors[selectedCharacterIndex % colors.count], size: CGSize(width: 34 * 0.8, height: 24 * 0.8))
            print("[CharacterUpdate] Using fallback color for character \(selectedCharacterIndex + 1)")
        }
        
        bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
        bird.zPosition = GameConstants.ZPositions.bird

        let radius = bird.size.height / 2.3
        if radius <= 0 {
            print("[CharacterUpdate] ERROR: Calculated physics radius <= 0. Bird size: \(bird.size). Using failsafe.")
            bird.physicsBody = SKPhysicsBody(circleOfRadius: 10) // Failsafe
        } else {
            bird.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        }
        
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.ground | PhysicsCategory.scoreNode
        bird.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.pipe
        bird.physicsBody?.affectedByGravity = false // Gravity enabled when game actually starts
        addChild(bird)
        bird.isHidden = true // Will be unhidden by proceedToGameStart
    }

    func proceedToGameStart() {
        // Remove character selection UI
        removeChildren(in: children.filter {
            $0.name == GameConstants.NodeNames.characterSelectionUI ||
            $0.name?.hasPrefix(GameConstants.NodeNames.characterPreviewPrefix) == true ||
            $0.name == GameConstants.NodeNames.startGameButton
        })
        characterPreviewBirds.removeAllChildren() // Clear from scene and array
        characterSelectionInstructionLabel?.removeFromParent()
        // selectCharacterTitleLabel?.removeFromParent() // If it were added

        characterSelectionActive = false
        
        updateBirdToSelectedCharacter() // Setup the actual bird for the game
        
        // Show game elements for "Ready" state
        tapToStartLabel.isHidden = false
        scoreLabel.isHidden = false
        highScoreLabel.isHidden = false
        bird.isHidden = false
        
        // Reset game state variables for a fresh "Ready" state
        gameOver = false
        gameStarted = false // Game hasn't started yet, player needs to tap
        score = 0
        isNewHighScore = false
        scoreLabel.text = "0"
        highScoreLabel.text = "Best: \(highScore)"
        tapToStartLabel.text = "Tap to Start"
        tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY) // Reset position if changed by game over
    }

    // --- Character Audio ---
    func playCharacterSelectionAudio(for characterIndex: Int) {
        guard let audioFileName = GameConstants.AudioFiles.characterFile(at: characterIndex) else {
            print("[Audio] Invalid character index for audio: \(characterIndex)")
            return
        }
        
        guard let audioPath = Bundle.main.path(forResource: audioFileName.replacingOccurrences(of: ".mp3", with: ""), ofType: "mp3") else {
            print("[Audio] ERROR: Audio file '\(audioFileName)' not found.")
            return
        }
        
        let audioUrl = URL(fileURLWithPath: audioPath)
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            audioPlayer?.volume = 0.7
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("[Audio] Playing: \(audioFileName)")
        } catch {
            print("[Audio] ERROR playing '\(audioFileName)': \(error.localizedDescription)")
        }
    }

    func stopCharacterAudio() {
        audioPlayer?.stop()
        audioPlayer = nil // Release the player
    }
}

// Helper for SKNode array
extension Array where Element: SKNode {
    mutating func removeAllChildren() {
        for node in self {
            node.removeFromParent()
        }
        self.removeAll()
    }
}
