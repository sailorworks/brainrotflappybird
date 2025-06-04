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

    // Character Selection
    var characterSelectionActive = false
    var selectedCharacterIndex = 0 // 0 = flappybird.png, 1 = flappybird2.png, 2 = flappybird3.png
    var characterTextures: [SKTexture] = []
    var characterPreviewBirds: [SKSpriteNode] = []
    var characterSelectionLabel: SKLabelNode!
    var selectCharacterLabel: SKLabelNode!


    // --- Scene Lifecycle ---

    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityStrength)
        physicsWorld.contactDelegate = self

        setupBackground()
        setupGround()
        // Bird needs to be initialized for the character selection logic to potentially hide/show it.
        // It will be fully configured by updateBirdCharacter later.
        setupBird()
        setupScoreLabel()
        setupTapToStartLabel()
        
        // Show character selection instead of game start
        setupCharacterSelection()
    }

    // --- Setup Methods ---

    func setupBackground() {
        // Try to load the background image first
        if let backgroundTexture = SKTexture(optionalImageNamed: "background-day.png") {
            backgroundTexture.filteringMode = .nearest
            
            let backgroundSprite = SKSpriteNode(texture: backgroundTexture)
            backgroundSprite.name = "background"
            backgroundSprite.zPosition = -10 // Behind everything else
            
            // Scale the background to fit the screen while maintaining aspect ratio
            let scaleX = self.frame.width / backgroundTexture.size().width
            let scaleY = self.frame.height / backgroundTexture.size().height
            let scale = max(scaleX, scaleY) // Use max to ensure full coverage
            
            backgroundSprite.scale(to: CGSize(width: backgroundTexture.size().width * scale,
                                             height: backgroundTexture.size().height * scale))
            
            // Center the background
            backgroundSprite.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            
            addChild(backgroundSprite)
            print("[BackgroundSetup] Background image loaded successfully. Original size: \(backgroundTexture.size()), Scaled size: \(backgroundSprite.size)")
        } else {
            // Fallback to sky blue color if image not found
            print("WARNING: background-day.png not found. Using sky blue color.")
            let skyColor = SKColor(red: 135.0/255.0, green: 206.0/255.0, blue: 235.0/255.0, alpha: 1.0)
            backgroundColor = skyColor
        }
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
        // This initial setup ensures 'bird' is not nil.
        // updateBirdCharacter will replace this with the selected character.
        // Using a placeholder texture initially.
        let initialTexture = SKTexture() // An empty texture
        bird = SKSpriteNode(texture: initialTexture)
        bird.size = CGSize(width: 34, height: 24) // A default small size
        bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
        bird.zPosition = 10
        // Initial physics body, will be re-created in updateBirdCharacter
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.3)
        bird.physicsBody!.isDynamic = true
        bird.physicsBody!.allowsRotation = false
        bird.physicsBody!.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody!.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.ground | PhysicsCategory.scoreNode
        bird.physicsBody!.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.pipe
        bird.physicsBody!.affectedByGravity = false
        addChild(bird)
        bird.isHidden = true // Hide initially, character selection screen will manage this
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
        scoreLabel.isHidden = true // Hide initially
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
        tapToStartLabel.isHidden = true // Hide initially
    }

    // --- Character Selection Functions ---

    func loadCharacterTextures() {
        let characterNames = ["flappybird.png", "flappybird2.png", "flappybird3.png"]
        characterTextures.removeAll()
        
        for name in characterNames {
            if let texture = SKTexture(optionalImageNamed: name) {
                texture.filteringMode = .nearest
                characterTextures.append(texture)
                print("[CharacterLoad] Loaded texture: \(name)")
            } else {
                print("[CharacterLoad] WARNING: Could not load \(name), using placeholder")
                // Create a placeholder colored texture if image not found
                let placeholderTexture = SKTexture()
                characterTextures.append(placeholderTexture)
            }
        }
    }

    func setupCharacterSelection() {
        characterSelectionActive = true
        loadCharacterTextures()
        
        // Hide existing game elements
        tapToStartLabel.isHidden = true
        scoreLabel.isHidden = true
        if bird != nil { // Ensure bird is not nil before accessing
          bird.isHidden = true
        }
        
        // Create selection title
        selectCharacterLabel = SKLabelNode(fontNamed: "04b_19")
        if UIFont(name: "04b_19", size: 1) == nil {
            selectCharacterLabel.fontName = "HelveticaNeue-Bold"
        }
//        selectCharacterLabel.text = "Choose Your Character"
//        selectCharacterLabel.fontSize = 35
//        selectCharacterLabel.fontColor = SKColor.white
//        selectCharacterLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 150)
//        selectCharacterLabel.zPosition = 20
//        selectCharacterLabel.name = "characterSelectionUI"
//        addChild(selectCharacterLabel)
        
        // Create instruction label
        characterSelectionLabel = SKLabelNode(fontNamed: "04b_19")
        if UIFont(name: "04b_19", size: 1) == nil {
            characterSelectionLabel.fontName = "HelveticaNeue-Bold"
        }
        characterSelectionLabel.text = "Tap on a character to select"
        characterSelectionLabel.fontSize = 20
        characterSelectionLabel.fontColor = SKColor.white
        characterSelectionLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 100)
        characterSelectionLabel.zPosition = 20
        characterSelectionLabel.name = "characterSelectionUI"
        addChild(characterSelectionLabel)
        
        // Create character preview birds
        characterPreviewBirds.removeAll() // Clear previous ones
        let spacing: CGFloat = 120
        let startX = self.frame.midX - spacing // Center the group of 3 birds
        
        for i in 0..<3 { // Assuming 3 characters
            let previewBird: SKSpriteNode
            
            // Check if texture exists and is valid (has a size)
            if i < characterTextures.count && characterTextures[i].size().width > 0 && characterTextures[i].size().height > 0 {
                let texture = characterTextures[i]
                previewBird = SKSpriteNode(texture: texture)
                // Scale preview bird to a consistent visual size, e.g., based on height
                let desiredHeight: CGFloat = 50.0
                let aspectRatio = texture.size().width / texture.size().height
                previewBird.size = CGSize(width: desiredHeight * aspectRatio, height: desiredHeight)
            } else {
                // Fallback colored birds if textures not available or are 0x0
                let colors: [SKColor] = [.orange, .red, .blue]
                previewBird = SKSpriteNode(color: colors[i % colors.count], size: CGSize(width: 40 * 1.2, height: 28 * 1.2))
            }
            
            previewBird.position = CGPoint(x: startX + (spacing * CGFloat(i)), y: self.frame.midY)
            previewBird.zPosition = 15
            previewBird.name = "characterPreview_\(i)"
            
            // Add selection indicator (border)
            let border = SKShapeNode(rect: CGRect(x: -previewBird.size.width/2 - 5,
                                                y: -previewBird.size.height/2 - 5,
                                                width: previewBird.size.width + 10,
                                                height: previewBird.size.height + 10))
            border.strokeColor = i == selectedCharacterIndex ? SKColor.yellow : SKColor.clear
            border.lineWidth = 3
            border.name = "selectionBorder"
            previewBird.addChild(border)
            
            // Add floating animation
            let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 1.0)
            let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 1.0)
            let floatSequence = SKAction.sequence([floatUp, floatDown])
            let floatForever = SKAction.repeatForever(floatSequence)
            previewBird.run(floatForever)
            
            characterPreviewBirds.append(previewBird)
            addChild(previewBird)
        }
        
        // Add "Start Game" button
        let startGameLabelNode = SKLabelNode(fontNamed: "04b_19") // Renamed to avoid conflict if 'startGameLabel' is a property
        if UIFont(name: "04b_19", size: 1) == nil {
            startGameLabelNode.fontName = "HelveticaNeue-Bold"
        }
        startGameLabelNode.text = "TAP TO START GAME"
        startGameLabelNode.fontSize = 25
        startGameLabelNode.fontColor = SKColor.green
        startGameLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 150)
        startGameLabelNode.zPosition = 20
        startGameLabelNode.name = "startGameButton"
        addChild(startGameLabelNode)
        
        print("[CharacterSelection] Character selection screen setup complete.")
    }

    func selectCharacter(_ index: Int) {
        guard index >= 0 && index < characterPreviewBirds.count else { return }
        
        // Update selection
        selectedCharacterIndex = index
        
        // Update visual indicators
        for (i, previewBird) in characterPreviewBirds.enumerated() {
            if let border = previewBird.childNode(withName: "selectionBorder") as? SKShapeNode {
                border.strokeColor = i == selectedCharacterIndex ? SKColor.yellow : SKColor.clear
            }
        }
        
        print("[CharacterSelection] Selected character \(index + 1)")
    }
    
    func updateBirdCharacter() {
        guard selectedCharacterIndex < characterTextures.count else {
            print("[CharacterUpdate] Invalid character index, using default")
            // If this happens, the bird won't be updated, which might be an issue.
            // Consider a default bird setup here if this guard can fail post-selection.
            return
        }
        
        let selectedTexture = characterTextures[selectedCharacterIndex]
        
        // Remove old bird instance before creating a new one
        if bird?.parent != nil { // bird can be nil if setupBird wasn't called or bird was removed elsewhere
            bird.removeFromParent()
        }
        
        // Create new bird with selected character
        // Your provided condition: !selectedTexture.description.isEmpty
        // This is true for SKTexture() placeholders, leading to 0x0 size.
        // A better check is for actual texture dimensions:
        if selectedTexture.size().width > 0 && selectedTexture.size().height > 0 {
            bird = SKSpriteNode(texture: selectedTexture)
            bird.size = CGSize(width: selectedTexture.size().width * 0.8,
                              height: selectedTexture.size().height * 0.8)
            print("[CharacterUpdate] Updated bird with character \(selectedCharacterIndex + 1)")
        } else {
            // Fallback if texture is placeholder (0x0 size) or otherwise invalid
            let colors: [SKColor] = [.orange, .red, .blue]
            // Use scaled default size for colored fallback
            bird = SKSpriteNode(color: colors[selectedCharacterIndex % colors.count], size: CGSize(width: 34 * 0.8, height: 24 * 0.8))
            print("[CharacterUpdate] Using fallback color for character \(selectedCharacterIndex + 1) as texture was invalid/empty.")
        }
        
        // Set bird properties
        bird.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY + 50)
        bird.zPosition = 10

        // Ensure physics body radius is based on a non-zero height.
        // bird.size is guaranteed to be > 0 by the if/else logic above.
        let radius = bird.size.height / 2.3
        if radius <= 0 {
             // This case should ideally not be reached if the size logic above is correct.
            print("[CharacterUpdate] ERROR: Calculated physics body radius is \(radius). Bird size: \(bird.size). Using failsafe radius.")
            bird.physicsBody = SKPhysicsBody(circleOfRadius: 10) // Failsafe radius
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
    }

    func startGameWithSelectedCharacter() {
        // Remove character selection UI
        removeChildren(in: children.filter { $0.name == "characterSelectionUI" ||
                                            $0.name?.hasPrefix("characterPreview_") == true ||
                                            $0.name == "startGameButton" })
        characterPreviewBirds.removeAll() // Clear the array
        if selectCharacterLabel?.parent != nil { selectCharacterLabel.removeFromParent() }
        if characterSelectionLabel?.parent != nil { characterSelectionLabel.removeFromParent() }

        characterSelectionActive = false
        
        // Update bird with selected character
        updateBirdCharacter() // This will create and add the new bird
        
        // Show game elements
        tapToStartLabel.isHidden = false
        scoreLabel.isHidden = false
        if bird != nil { // bird should be non-nil after updateBirdCharacter
            bird.isHidden = false
        }
        
        // Reset game state for a fresh start before "Tap to Start"
        gameOver = false
        gameStarted = false
        score = 0
        scoreLabel.text = "0"
        tapToStartLabel.text = "Tap to Start"

        // Bird physics and position are set in updateBirdCharacter.
        // Gravity will be enabled in startGame() upon the next tap.
    }


    // --- Game Logic ---

    func startGame() {
        guard bird != nil else {
            print("Error: Bird node is nil. Cannot start game.")
            return
        }
        
        gameStarted = true
        gameOver = false
        // Score is reset when transitioning from character selection or in resetGame
        // scoreLabel.text = "0"
        tapToStartLabel.isHidden = true
        bird.isHidden = false // Ensure bird is visible
        
        // Activate bird physics
        bird.physicsBody?.affectedByGravity = true
        bird.physicsBody?.velocity = CGVector.zero
        // Initial position/rotation should be set by updateBirdCharacter or resetGame logic
        
        resetGroundPositions() // Ensure ground is correctly positioned and starts moving
        
        // Start pipe spawning
        pipeSpawnTimer?.invalidate()
        pipeSpawnTimer = Timer.scheduledTimer(timeInterval: pipeSpawnInterval, target: self, selector: #selector(spawnPipePair), userInfo: nil, repeats: true)
        print("[GameLogic] startGame() called, pipeSpawnTimer started.")
        
        moveGround() // Start ground movement
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
        // print("[PipeSpawnDebug] Attempting to spawn pipe pair...") // Reduce log noise

        guard let bottomPipeTexture = SKTexture(optionalImageNamed: "pipe.png") else {
            print("[PipeSpawnDebug] ERROR: Bottom pipe texture (pipe.png) not found. Skipping pipe spawn.")
            return
        }
        guard let topPipeTexture = SKTexture(optionalImageNamed: "pipeinverted.png") else {
            print("[PipeSpawnDebug] ERROR: Top pipe texture (pipeinverted.png) not found. Skipping pipe spawn.")
            return
        }
        // print("[PipeSpawnDebug] Core pipe textures loaded.") // Reduce log noise
        bottomPipeTexture.filteringMode = .nearest
        topPipeTexture.filteringMode = .nearest

        let pipeImageWidth = bottomPipeTexture.size().width

        let groundSpriteNode = ground.children.first as? SKSpriteNode
        let groundHeight = groundSpriteNode?.size.height ?? 80.0

        let minGapBottomY = groundHeight + verticalPaddingForPipes + 50.0
        let maxGapBottomY = self.frame.height - verticalPaddingForPipes - 50.0 - pipeGap
        
        guard maxGapBottomY > minGapBottomY else {
            print("[PipeSpawnDebug] CRITICAL ERROR: Not enough vertical space for gap positioning. MinGapBottomY: \(minGapBottomY), MaxGapBottomY: \(maxGapBottomY)")
            return
        }
        let gapBottomY = CGFloat.random(in: minGapBottomY...maxGapBottomY)
        let gapTopY = gapBottomY + pipeGap

        // print("[PipeSpawnDebug] ScreenH: \(self.frame.height), GroundH: \(groundHeight), Padding: \(verticalPaddingForPipes), PipeGap: \(pipeGap)") // Reduce log noise
        // print("[PipeSpawnDebug] Chosen GapBottomY: \(gapBottomY), GapTopY: \(gapTopY)") // Reduce log noise


        let spawnXPosition = self.frame.maxX + pipeImageWidth / 2
        var nodesToAnimate: [SKNode] = []

        let bottomPipeHeight = gapBottomY - groundHeight
        
        guard bottomPipeHeight > 0 else {
            // print("[PipeSpawnDebug] Bottom pipe height is zero or negative. Skipping. \(bottomPipeHeight)") // Reduce log noise
            return
        }

        let bottomPipe = SKSpriteNode(texture: bottomPipeTexture)
        bottomPipe.name = "pipe"
        bottomPipe.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bottomPipe.size = CGSize(width: pipeImageWidth, height: bottomPipeHeight)
        bottomPipe.position = CGPoint(x: spawnXPosition, y: groundHeight)
        
        // print("[PipeSpawnDebug] BottomPipe: pos Y \(bottomPipe.position.y), height \(bottomPipe.size.height). Top edge should be at \(bottomPipe.position.y + bottomPipe.size.height)") // Reduce log noise

        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size, center: CGPoint(x: 0, y: bottomPipe.size.height / 2))
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        bottomPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        bottomPipe.physicsBody?.collisionBitMask = PhysicsCategory.bird
        bottomPipe.zPosition = 5
        addChild(bottomPipe)
        nodesToAnimate.append(bottomPipe)


        let topPipeHeight = self.frame.height - gapTopY
        
        guard topPipeHeight > 0 else {
            // print("[PipeSpawnDebug] Top pipe height is zero or negative. Skipping. \(topPipeHeight)") // Reduce log noise
            return
        }

        let topPipe = SKSpriteNode(texture: topPipeTexture)
        topPipe.name = "pipe"
        topPipe.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        topPipe.size = CGSize(width: pipeImageWidth, height: topPipeHeight)
        topPipe.position = CGPoint(x: spawnXPosition, y: self.frame.height)
        
        // print("[PipeSpawnDebug] TopPipe: pos Y \(topPipe.position.y), height \(topPipe.size.height). Bottom edge should be at \(topPipe.position.y - topPipe.size.height)") // Reduce log noise

        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size, center: CGPoint(x: 0, y: -topPipe.size.height / 2))
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        topPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        topPipe.physicsBody?.collisionBitMask = PhysicsCategory.bird
        topPipe.zPosition = 5
        addChild(topPipe)
        nodesToAnimate.append(topPipe)
        
        let scoreNode = SKNode()
        scoreNode.name = "scoreNode"
        scoreNode.position = CGPoint(x: spawnXPosition, y: (gapBottomY + gapTopY) / 2)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: pipeGap))
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.scoreNode
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        scoreNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(scoreNode)
        nodesToAnimate.append(scoreNode)
        // print("[PipeSpawnDebug] ScoreNode position Y: \(scoreNode.position.y)") // Reduce log noise

        let moveDistance = self.frame.width + pipeImageWidth
        let pointsPerSecondSpeed = pipeSpeed * 60.0
        let moveDuration = TimeInterval(moveDistance / pointsPerSecondSpeed)

        let moveAction = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])

        for node in nodesToAnimate {
            node.run(sequence)
        }
        // print("[PipeSpawnDebug] All pipe parts created and actions started.\n---") // Reduce log noise
    }
    
    func moveGround() {
        let groundScrollSpeed = pipeSpeed * 60.0
        
        let groundSprites = ground.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name == "ground" }
        
        guard !groundSprites.isEmpty else {
            print("[GroundError] No ground sprites found to animate!")
            return
        }
        
        for groundSprite in groundSprites {
            let moveDurationPerSprite = TimeInterval(groundSprite.size.width / groundScrollSpeed)
            
            let moveLeft = SKAction.moveBy(x: -groundSprite.size.width, y: 0, duration: moveDurationPerSprite)
            let resetPosition = SKAction.moveBy(x: groundSprite.size.width, y: 0, duration: 0)
            let sequence = SKAction.sequence([moveLeft, resetPosition])
            let repeatForever = SKAction.repeatForever(sequence)
            
            groundSprite.removeAction(forKey: "moveGround")
            groundSprite.run(repeatForever, withKey: "moveGround")
        }
        
        // print("[GroundMovement] Started scrolling for \(groundSprites.count) ground sprites.") // Reduce log noise
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
        
        pipeSpawnTimer?.invalidate()
        pipeSpawnTimer = nil
        
        self.enumerateChildNodes(withName: "//*") { (node, _) in
            if node.name == "pipe" || node.name == "scoreNode" {
                node.removeAllActions()
            }
        }
        
        stopGroundScrolling()
        
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
        
        resetGroundPositions() // Stops and resets ground
        
        // Game state reset happens in setupCharacterSelection
        // gameOver = false
        // gameStarted = false
        // score = 0
        // scoreLabel.text = "0"
        
        // tapToStartLabel.text = "Tap to Start"
        // tapToStartLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        // Go back to character selection
        setupCharacterSelection()
    }
    
    func resetGroundPositions() {
        stopGroundScrolling()
        
        var index = 0
        for node in ground.children where node.name == "ground" {
            guard let groundSprite = node as? SKSpriteNode else { continue }
            groundSprite.position = CGPoint(x: CGFloat(index) * groundSprite.size.width, y: 0)
            index += 1
        }
        // print("[GroundReset] Ground positions reset. Sprites repositioned.") // Reduce log noise
    }

    // --- Input Handling ---

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        if characterSelectionActive {
            // Check if start game button was tapped
            if let startButton = childNode(withName: "startGameButton") {
                if startButton.contains(touchLocation) {
                    startGameWithSelectedCharacter()
                    return
                }
            }
            
            // Check if a character preview was tapped
            for (index, previewBird) in characterPreviewBirds.enumerated() {
                if previewBird.contains(touchLocation) {
                    selectCharacter(index)
                    return
                }
            }
        } else {
            // Original game touch handling
            if !gameStarted {
                if gameOver {
                    resetGame() // This will now go to character selection
                } else {
                    // This is after character selection, "Tap to Start" is showing
                    startGame()
                    flapBird()
                }
            } else if !gameOver { // Game is active
                flapBird()
            }
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
        // Check if bird fell off screen (more robustly, e.g., below ground level if ground is defined)
        if bird != nil && bird.position.y < (ground.children.first as? SKSpriteNode)?.frame.minY ?? 0 && !gameOver {
             // More simply, if bird is way off screen bottom:
             if bird.position.y < -self.frame.size.height / 2 && !gameOver { // Significantly off-screen
                 triggerGameOver()
             }
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
