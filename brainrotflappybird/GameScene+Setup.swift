import SpriteKit
import AVFoundation

extension GameScene {

    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("[Audio] Audio session configured successfully")
        } catch {
            print("[Audio] ERROR: Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    func setupBackground() {
        if let backgroundTexture = SKTexture(optionalImageNamed: GameConstants.ImageNames.background) {
            backgroundTexture.filteringMode = .nearest
            
            let backgroundSprite = SKSpriteNode(texture: backgroundTexture)
            backgroundSprite.name = GameConstants.NodeNames.background
            backgroundSprite.zPosition = GameConstants.ZPositions.background
            
            let scaleX = self.frame.width / backgroundTexture.size().width
            let scaleY = self.frame.height / backgroundTexture.size().height
            let scale = max(scaleX, scaleY)
            
            backgroundSprite.scale(to: CGSize(width: backgroundTexture.size().width * scale,
                                             height: backgroundTexture.size().height * scale))
            backgroundSprite.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            addChild(backgroundSprite)
            print("[BackgroundSetup] Background image loaded. Original: \(backgroundTexture.size()), Scaled: \(backgroundSprite.size)")
        } else {
            print("WARNING: \(GameConstants.ImageNames.background) not found. Using sky blue color.")
            let skyColor = SKColor(red: 135.0/255.0, green: 206.0/255.0, blue: 235.0/255.0, alpha: 1.0)
            backgroundColor = skyColor
        }
    }

    func setupGround() {
        ground = SKNode()
        ground.position = CGPoint(x: 0, y: 0)
        ground.zPosition = GameConstants.ZPositions.ground
        ground.name = GameConstants.NodeNames.ground // Name the parent ground node for easier identification if needed

        for i in 0...1 {
            let groundSprite: SKSpriteNode
            if let tex = SKTexture(optionalImageNamed: GameConstants.ImageNames.ground) {
                tex.filteringMode = .nearest
                groundSprite = SKSpriteNode(texture: tex)
                let aspectRatio = tex.size().height / tex.size().width
                let scaledHeight = self.frame.width * aspectRatio
                groundSprite.size = CGSize(width: self.frame.width, height: scaledHeight)
                print("[GroundSetup] Texture loaded. Original: \(tex.size()), Scaled: \(groundSprite.size)")
            } else {
                print("WARNING: \(GameConstants.ImageNames.ground) not found. Using brown rectangle.")
                groundSprite = SKSpriteNode(color: SKColor(red: 222/255.0, green: 184/255.0, blue: 135/255.0, alpha: 1.0),
                                             size: CGSize(width: self.frame.width, height: 80))
                print("[GroundSetup] Texture NOT loaded. Fallback size: \(groundSprite.size)")
            }

            groundSprite.anchorPoint = CGPoint.zero
            groundSprite.position = CGPoint(x: CGFloat(i) * groundSprite.size.width, y: 0)
            groundSprite.name = GameConstants.NodeNames.ground // Name individual ground segments too

            groundSprite.physicsBody = SKPhysicsBody(rectangleOf: groundSprite.size, center: CGPoint(x: groundSprite.size.width / 2, y: groundSprite.size.height / 2))
            groundSprite.physicsBody?.isDynamic = false
            groundSprite.physicsBody?.categoryBitMask = PhysicsCategory.ground
            groundSprite.physicsBody?.contactTestBitMask = PhysicsCategory.bird
            groundSprite.physicsBody?.collisionBitMask = PhysicsCategory.bird
            ground.addChild(groundSprite)
        }
        addChild(ground)
    }

    func setupBird() {
        // Initial placeholder bird setup. Will be replaced by `updateBirdCharacter`.
        let initialTexture = SKTexture() // Empty texture
        bird = SKSpriteNode(texture: initialTexture)
        bird.size = CGSize(width: 34, height: 24) // Default small size
        bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
        bird.zPosition = GameConstants.ZPositions.bird
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.3) // Will be re-created
        bird.physicsBody!.isDynamic = true
        bird.physicsBody!.allowsRotation = false
        bird.physicsBody!.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody!.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.ground | PhysicsCategory.scoreNode
        bird.physicsBody!.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.pipe
        bird.physicsBody!.affectedByGravity = false
        addChild(bird)
        bird.isHidden = true // Hidden until character selection is done and game starts
    }

    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        if UIFont(name: GameConstants.FontNames.main, size: 1) == nil {
            print("WARNING: \(GameConstants.FontNames.main) font not found. Using \(GameConstants.FontNames.fallback).")
            scoreLabel.fontName = GameConstants.FontNames.fallback
        }
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 100)
        scoreLabel.zPosition = GameConstants.ZPositions.scoreLabel
        scoreLabel.text = "0"
        addChild(scoreLabel)
        scoreLabel.isHidden = true // Hidden initially

        // Setup high score label as part of this
        setupHighScoreDisplayLabel()
    }

    func setupHighScoreDisplayLabel() { // Renamed from setupHighScoreLabel to avoid confusion
        highScoreLabel = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        if UIFont(name: GameConstants.FontNames.main, size: 1) == nil {
            highScoreLabel.fontName = GameConstants.FontNames.fallback
        }
        highScoreLabel.fontSize = 35
        highScoreLabel.fontColor = SKColor.yellow
        highScoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 160)
        highScoreLabel.zPosition = GameConstants.ZPositions.highScoreDisplay
        highScoreLabel.text = "Best: \(highScore)" // highScore property should be loaded by now
        addChild(highScoreLabel)
        highScoreLabel.isHidden = true // Hide initially
    }

    func setupTapToStartLabel() {
        tapToStartLabel = SKLabelNode(fontNamed: GameConstants.FontNames.main)
        if UIFont(name: GameConstants.FontNames.main, size: 1) == nil {
            tapToStartLabel.fontName = GameConstants.FontNames.fallback
        }
        tapToStartLabel.text = "Tap to Start"
        tapToStartLabel.fontSize = 30
        tapToStartLabel.fontColor = SKColor.white
        tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        tapToStartLabel.zPosition = GameConstants.ZPositions.tapToStartLabel
        addChild(tapToStartLabel)
        tapToStartLabel.isHidden = true // Hide initially
    }
}//
//  GameScene+Setup.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

