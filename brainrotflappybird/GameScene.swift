import SpriteKit
import GameplayKit

// Physics Categories
struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let bird      : UInt32 = 0b1       // 1
    static let ground    : UInt32 = 0b10      // 2
    static let pipe      : UInt32 = 0b100     // 4
    static let scoreNode : UInt32 = 0b1000    // 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    // Game Objects
    var bird: SKSpriteNode!
    var ground: SKNode!
    var pipeSpawnTimer: Timer?
    var scoreLabel: SKLabelNode!
    var tapToStartLabel: SKLabelNode!

    // Game State
    var gameStarted = false
    var gameOver = false
    var score = 0

    // Constants
    let birdFlapForce: CGFloat = 25.0
    let gravityStrength: CGFloat = -7.0
    let pipeSpeed: CGFloat = 2.5

    // THESE ARE THE VALUES FROM YOUR LATEST LOG - ADJUST THEM ALONG WITH IMAGE SIZES
    let pipeGap: CGFloat = 180.0      // Adjusted from your log
    let verticalPaddingForPipes: CGFloat = 15.0 // Adjusted from your log

    let pipeSpawnInterval: TimeInterval = 1.5


    // --- Scene Lifecycle ---

    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityStrength)
        physicsWorld.contactDelegate = self

        setupBackground()
        setupGround()
        setupBird()
        setupScoreLabel()
        setupTapToStartLabel()
    }

    // --- Setup Methods ---

    func setupBackground() {
        let skyColor = SKColor(red: 135.0/255.0, green: 206.0/255.0, blue: 235.0/255.0, alpha: 1.0)
        backgroundColor = skyColor
    }

    func setupGround() {
        ground = SKNode()
        ground.position = CGPoint(x: 0, y: 0)
        ground.zPosition = 1

        for i in 0...1 {
            let groundSprite: SKSpriteNode
            if let tex = SKTexture(optionalImageNamed: "ground_pixelated") {
                tex.filteringMode = .nearest
                groundSprite = SKSpriteNode(texture: tex)
                let aspectRatio = tex.size().height / tex.size().width
                let scaledHeight = self.frame.width * aspectRatio
                groundSprite.size = CGSize(width: self.frame.width, height: scaledHeight)
                print("[GroundSetup] Ground texture loaded. Original size: \(tex.size()), Scaled size: \(groundSprite.size)")
            } else {
                print("WARNING: ground_pixelated.png not found. Using a brown rectangle.")
                groundSprite = SKSpriteNode(color: SKColor(red: 222/255.0, green: 184/255.0, blue: 135/255.0, alpha: 1.0),
                                             size: CGSize(width: self.frame.width, height: 80))
                 print("[GroundSetup] Ground texture NOT loaded. Using fallback size: \(groundSprite.size)")
            }

            groundSprite.anchorPoint = CGPoint.zero
            groundSprite.position = CGPoint(x: CGFloat(i) * groundSprite.size.width, y: 0)
            groundSprite.name = "ground"

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
        guard let birdTexture = SKTexture(optionalImageNamed: "flappybird") else {
            print("FATAL ERROR: flappybird.png texture not found. Creating placeholder bird.")
            bird = SKSpriteNode(color: .orange, size: CGSize(width: 34, height: 24))
            bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
            bird.zPosition = 10
            bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.3)
            bird.physicsBody!.isDynamic = true
            bird.physicsBody!.allowsRotation = false
            bird.physicsBody!.categoryBitMask = PhysicsCategory.bird
            bird.physicsBody!.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.ground | PhysicsCategory.scoreNode
            bird.physicsBody!.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.pipe
            bird.physicsBody!.affectedByGravity = false
            addChild(bird)
            return
        }
        birdTexture.filteringMode = .nearest
        bird = SKSpriteNode(texture: birdTexture)
        bird.size = CGSize(width: birdTexture.size().width * 0.8, height: birdTexture.size().height * 0.8)
        bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
        bird.zPosition = 10
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.3)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.ground | PhysicsCategory.scoreNode
        bird.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.pipe
        bird.physicsBody?.affectedByGravity = false
        addChild(bird)
    }

    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "04b_19")
        if UIFont(name: "04b_19", size: 1) == nil {
            print("WARNING: 04b_19 font not found. Using HelveticaNeue-Bold.")
            scoreLabel.fontName = "HelveticaNeue-Bold"
        }
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 100)
        scoreLabel.zPosition = 20
        scoreLabel.text = "0"
        addChild(scoreLabel)
    }

    func setupTapToStartLabel() {
        tapToStartLabel = SKLabelNode(fontNamed: "04b_19")
        if UIFont(name: "04b_19", size: 1) == nil {
            tapToStartLabel.fontName = "HelveticaNeue-Bold"
        }
        tapToStartLabel.text = "Tap to Start"
        tapToStartLabel.fontSize = 30
        tapToStartLabel.fontColor = SKColor.white
        tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        tapToStartLabel.zPosition = 20
        addChild(tapToStartLabel)
    }

    // --- Game Logic ---

    func startGame() {
        guard bird != nil else {
            print("Error: Bird node is nil. Cannot start game.")
            return
        }
        
        gameStarted = true
        gameOver = false
        score = 0
        scoreLabel.text = "0"
        tapToStartLabel.isHidden = true
        
        // Reset bird
        bird.physicsBody?.affectedByGravity = true
        bird.physicsBody?.velocity = CGVector.zero
        bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
        bird.zRotation = 0
        
        // Ensure ground is properly positioned before starting movement
        if !gameStarted || gameOver {
            resetGroundPositions()
        }
        
        // Start pipe spawning
        pipeSpawnTimer?.invalidate()
        pipeSpawnTimer = Timer.scheduledTimer(timeInterval: pipeSpawnInterval, target: self, selector: #selector(spawnPipePair), userInfo: nil, repeats: true)
        print("[GameLogic] startGame() called, pipeSpawnTimer started.")
        
        // Start ground movement
        moveGround()
    }
    
    func flapBird() {
        guard gameStarted && !gameOver, bird != nil else { return }
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: birdFlapForce))
        let flapUpAction = SKAction.rotate(toAngle: 0.3, duration: 0.1)
        bird.run(flapUpAction)
    }

    @objc func spawnPipePair() {
        guard gameStarted && !gameOver else { return }
        print("[PipeSpawnDebug] Attempting to spawn pipe pair...")

        guard let bottomPipeTexture = SKTexture(optionalImageNamed: "pipe.png") else {
            print("[PipeSpawnDebug] ERROR: Bottom pipe texture (pipe.png) not found. Skipping pipe spawn.")
            return
        }
        guard let topPipeTexture = SKTexture(optionalImageNamed: "pipeinverted.png") else {
            print("[PipeSpawnDebug] ERROR: Top pipe texture (pipeinverted.png) not found. Skipping pipe spawn.")
            return
        }
        print("[PipeSpawnDebug] Core pipe textures loaded.")
        bottomPipeTexture.filteringMode = .nearest
        topPipeTexture.filteringMode = .nearest
        // If you want textures to tile instead of stretch (looks better but more complex setup)
        // bottomPipeTexture.usesMipmaps = false // Optional
        // topPipeTexture.usesMipmaps = false    // Optional


        let pipeImageWidth = bottomPipeTexture.size().width // Use the width from your image
        // We will determine heights dynamically.

        let groundSpriteNode = ground.children.first as? SKSpriteNode
        let groundHeight = groundSpriteNode?.size.height ?? 80.0

        // Determine the Y position for the bottom of the gap
        // Min: Ground + Padding + Min Visible Pipe Body (e.g., 50)
        // Max: Screen Height - Padding - Min Visible Pipe Body - Gap Height
        let minGapBottomY = groundHeight + verticalPaddingForPipes + 50.0 // 50 is an arbitrary min height for top pipe body
        let maxGapBottomY = self.frame.height - verticalPaddingForPipes - 50.0 - pipeGap // 50 for bottom pipe body
        
        guard maxGapBottomY > minGapBottomY else {
            print("[PipeSpawnDebug] CRITICAL ERROR: Not enough vertical space for gap positioning. MinGapBottomY: \(minGapBottomY), MaxGapBottomY: \(maxGapBottomY)")
            return
        }
        // This is the Y coordinate of the bottom opening of the gap (top of the bottom pipe's opening)
        let gapBottomY = CGFloat.random(in: minGapBottomY...maxGapBottomY)
        // This is the Y coordinate of the top opening of the gap (bottom of the top pipe's opening)
        let gapTopY = gapBottomY + pipeGap

        print("[PipeSpawnDebug] ScreenH: \(self.frame.height), GroundH: \(groundHeight), Padding: \(verticalPaddingForPipes), PipeGap: \(pipeGap)")
        print("[PipeSpawnDebug] Chosen GapBottomY: \(gapBottomY), GapTopY: \(gapTopY)")


        let spawnXPosition = self.frame.maxX + pipeImageWidth / 2
        var nodesToAnimate: [SKNode] = []

        // --- Bottom Pipe (pipe.png) ---
        // This pipe will extend from the ground (plus padding) up to gapBottomY
        let bottomPipeHeight = gapBottomY - groundHeight // Height of the visible part of bottom pipe
        
        guard bottomPipeHeight > 0 else {
            print("[PipeSpawnDebug] Bottom pipe height is zero or negative. Skipping. \(bottomPipeHeight)")
            return
        }

        let bottomPipe = SKSpriteNode(texture: bottomPipeTexture)
        bottomPipe.name = "pipe"
        // Anchor at the very bottom of the texture, so we can position it at ground level
        // and then scale its height upwards.
        bottomPipe.anchorPoint = CGPoint(x: 0.5, y: 0.0) // BOTTOM-CENTER
        bottomPipe.size = CGSize(width: pipeImageWidth, height: bottomPipeHeight)
        // Position its bottom edge at the ground level (or slightly above if you want padding *below* the pipe texture)
        bottomPipe.position = CGPoint(x: spawnXPosition, y: groundHeight) // + verticalPaddingForPipes if you want padding *under* the pipe.
                                                                          // Or 0 if groundHeight is 0 and ground is just visual
        
        print("[PipeSpawnDebug] BottomPipe: pos Y \(bottomPipe.position.y), height \(bottomPipe.size.height). Top edge should be at \(bottomPipe.position.y + bottomPipe.size.height)")

        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size, center: CGPoint(x: 0, y: bottomPipe.size.height / 2)) // Physics body relative to anchor
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        // ... (rest of physics setup)
        bottomPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        bottomPipe.physicsBody?.collisionBitMask = PhysicsCategory.bird
        bottomPipe.zPosition = 5
        addChild(bottomPipe)
        nodesToAnimate.append(bottomPipe)


        // --- Top Pipe (pipeinverted.png) ---
        // This pipe will extend from gapTopY up to the top of the screen (minus padding)
        let topPipeHeight = self.frame.height - gapTopY // Height of the visible part of top pipe
        
        guard topPipeHeight > 0 else {
            print("[PipeSpawnDebug] Top pipe height is zero or negative. Skipping. \(topPipeHeight)")
            return
        }

        let topPipe = SKSpriteNode(texture: topPipeTexture)
        topPipe.name = "pipe"
        // Anchor at the very top of the texture.
        topPipe.anchorPoint = CGPoint(x: 0.5, y: 1.0) // TOP-CENTER
        topPipe.size = CGSize(width: pipeImageWidth, height: topPipeHeight)
        // Position its top edge at the top of the screen
        topPipe.position = CGPoint(x: spawnXPosition, y: self.frame.height) // - verticalPaddingForPipes if you want padding *above* the pipe
        
        print("[PipeSpawnDebug] TopPipe: pos Y \(topPipe.position.y), height \(topPipe.size.height). Bottom edge should be at \(topPipe.position.y - topPipe.size.height)")

        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size, center: CGPoint(x: 0, y: -topPipe.size.height / 2)) // Physics body relative to anchor
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        // ... (rest of physics setup)
        topPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        topPipe.physicsBody?.collisionBitMask = PhysicsCategory.bird
        topPipe.zPosition = 5
        addChild(topPipe)
        nodesToAnimate.append(topPipe)
        
        // --- Score Node ---
        let scoreNode = SKNode()
        scoreNode.name = "scoreNode"
        // Vertically centered in the actual visual gap
        scoreNode.position = CGPoint(x: spawnXPosition, y: (gapBottomY + gapTopY) / 2)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: pipeGap)) // Height is the defined gap
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.scoreNode
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        scoreNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(scoreNode)
        nodesToAnimate.append(scoreNode)
        print("[PipeSpawnDebug] ScoreNode position Y: \(scoreNode.position.y)")

        // --- Move and Remove Actions ---
        let moveDistance = self.frame.width + pipeImageWidth
        let pointsPerSecondSpeed = pipeSpeed * 60.0
        let moveDuration = TimeInterval(moveDistance / pointsPerSecondSpeed)

        let moveAction = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])

        for node in nodesToAnimate {
            node.run(sequence)
        }
        print("[PipeSpawnDebug] All pipe parts created and actions started.\n---")
    }
    
    func moveGround() {
        let groundScrollSpeed = pipeSpeed * 60.0
        
        // First, ensure we have ground sprites
        let groundSprites = ground.children.compactMap { node -> SKSpriteNode? in
            guard node.name == "ground", let sprite = node as? SKSpriteNode else { return nil }
            return sprite
        }
        
        guard !groundSprites.isEmpty else {
            print("[GroundError] No ground sprites found to animate!")
            return
        }
        
        for groundSprite in groundSprites {
            // Calculate proper duration based on ground sprite width
            let moveDurationPerSprite = TimeInterval(groundSprite.size.width / groundScrollSpeed)
            
            // Create smooth continuous scrolling actions
            let moveLeft = SKAction.moveBy(x: -groundSprite.size.width, y: 0, duration: moveDurationPerSprite)
            let resetPosition = SKAction.moveBy(x: groundSprite.size.width, y: 0, duration: 0)
            let sequence = SKAction.sequence([moveLeft, resetPosition])
            let repeatForever = SKAction.repeatForever(sequence)
            
            // Remove any existing ground movement before starting new one
            groundSprite.removeAction(forKey: "moveGround")
            groundSprite.run(repeatForever, withKey: "moveGround")
        }
        
        print("[GroundMovement] Started scrolling for \(groundSprites.count) ground sprites.")
    }

    func stopGroundScrolling() {
        for node in ground.children where node.name == "ground" {
            node.removeAction(forKey: "moveGround")
        }
    }
    func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true
        gameStarted = false
        
        if bird != nil {
            bird.physicsBody?.affectedByGravity = false
            bird.physicsBody?.velocity = CGVector.zero
        }
        
        // Stop pipe spawning
        pipeSpawnTimer?.invalidate()
        pipeSpawnTimer = nil
        
        // Stop all node actions (including pipes)
        self.enumerateChildNodes(withName: "//*") { (node, _) in
            if node.name == "pipe" || node.name == "scoreNode" {
                node.removeAllActions()
            }
        }
        
        // Stop ground scrolling but don't reset positions yet
        stopGroundScrolling()
        
        // Add game over UI
        let gameOverLabel = SKLabelNode(fontNamed: "04b_19")
        if UIFont(name: "04b_19", size: 1) == nil {
            gameOverLabel.fontName = "HelveticaNeue-Bold"
        }
        gameOverLabel.text = "Game Over"
        gameOverLabel.name = "gameOverLabel"
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 50)
        gameOverLabel.zPosition = 30
        addChild(gameOverLabel)
        
        tapToStartLabel.text = "Tap to Restart"
        tapToStartLabel.isHidden = false
        tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 50)
    }


    func resetGame() {
        // Remove game objects
        self.removeChildren(in: self.children.filter {
            $0.name == "pipe" || $0.name == "scoreNode" || $0.name == "gameOverLabel"
        })
        
        // Reset ground positions properly
        resetGroundPositions()
        
        // Reset labels
        tapToStartLabel.text = "Tap to Start"
        tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        // Start new game
        startGame()
    }
    
    func resetGroundPositions() {
        // Stop any existing ground movement
        stopGroundScrolling()
        
        // Reset ground sprite positions to their original state
        var index = 0
        for node in ground.children where node.name == "ground" {
            guard let groundSprite = node as? SKSpriteNode else { continue }
            
            // Reset to original positions (side by side)
            groundSprite.position = CGPoint(x: CGFloat(index) * groundSprite.size.width, y: 0)
            index += 1
        }
        
        print("[GroundReset] Ground positions reset. Sprites repositioned.")
    }

    // --- Input Handling ---

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameStarted {
            if gameOver {
                resetGame()
            } else {
                startGame()
                flapBird()
            }
        } else if !gameOver {
            flapBird()
        }
    }

    // --- Physics Contact Delegate ---

    func didBegin(_ contact: SKPhysicsContact) {
        guard !gameOver else { return }
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask == PhysicsCategory.bird && (secondBody.categoryBitMask == PhysicsCategory.pipe || secondBody.categoryBitMask == PhysicsCategory.ground)) {
            if firstBody.node != nil && secondBody.node != nil {
                 triggerGameOver()
            }
        }
        else if (firstBody.categoryBitMask == PhysicsCategory.bird && secondBody.categoryBitMask == PhysicsCategory.scoreNode) {
            if let node = secondBody.node {
                score += 1
                scoreLabel.text = "\(score)"
                node.removeFromParent()
            }
        }
    }

    // --- Update Loop ---

    override func update(_ currentTime: TimeInterval) {
        if gameStarted && !gameOver && bird != nil {
            if let dy = bird.physicsBody?.velocity.dy {
                let rotation = max(min(dy * 0.002, 0.5), -0.8)
                bird.zRotation = rotation
            }
        }
        if bird != nil && bird.position.y < -(bird.size.height / 2) && !gameOver {
             triggerGameOver()
        }
    }
}

// Helper extension
extension SKTexture {
    convenience init?(optionalImageNamed name: String) {
        if UIImage(named: name) != nil {
            self.init(imageNamed: name)
        } else {
            print("SKTEXTURE WARNING: Texture image named '\(name)' not found in bundle.")
            return nil
        }
    }
}

// Added missing SKBody alias for SKPhysicsBody - ensure this is SKPhysicsBody
typealias SKBody = SKPhysicsBody
