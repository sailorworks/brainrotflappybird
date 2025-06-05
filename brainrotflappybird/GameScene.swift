import SpriteKit
import GameplayKit // Keep for GameplayKit components if any are used later, otherwise optional
import AVFoundation

class GameScene: SKScene {

    // Game Objects
    var bird: SKSpriteNode!
    var ground: SKNode!
    var pipeSpawnTimer: Timer?
    var scoreLabel: SKLabelNode!
    var tapToStartLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode! // For displaying high score during gameplay/ready
    var newHighScoreLabel: SKLabelNode! // For "NEW HIGH SCORE!" message

    // Game State
    var gameStarted = false
    var gameOver = false
    var score = 0
    var highScore = 0
    var isNewHighScore = false // Tracks if current game resulted in a new high score

    // Audio
    var audioPlayer: AVAudioPlayer?

    // Character Selection
    var characterSelectionActive = false
    var selectedCharacterIndex = 0 // Default selected character
    var characterTextures: [SKTexture] = []
    var characterPreviewBirds: [SKSpriteNode] = []
    var characterSelectionInstructionLabel: SKLabelNode! // Renamed from characterSelectionLabel for clarity
    // var selectCharacterTitleLabel: SKLabelNode! // Corresponds to the commented-out "Choose Your Character"

    // --- Scene Lifecycle ---
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: GameConstants.gravityStrength)
        physicsWorld.contactDelegate = self // Conformance is in the class declaration, implementation in GameScene+Physics.swift

        // Initial Setup
        setupAudioSession()
        setupBackground()
        setupGround()
        setupBird() // Sets up a placeholder bird initially
        setupScoreLabel() // Also sets up highScoreLabel
        setupTapToStartLabel()
        
        loadHighScore() // Load from UserDefaults

        // Start with character selection screen
        setupCharacterSelectionScreen()
    }
}
