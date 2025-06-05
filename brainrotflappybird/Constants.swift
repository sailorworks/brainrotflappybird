import SpriteKit // For CGFloat, SKTexture etc.
import CoreGraphics // For CGFloat

// Physics Categories
struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let bird      : UInt32 = 0b1       // 1
    static let ground    : UInt32 = 0b10      // 2
    static let pipe      : UInt32 = 0b100     // 4
    static let scoreNode : UInt32 = 0b1000    // 8
}

struct GameConstants {
    static let birdFlapForce: CGFloat = 25.0
    static let gravityStrength: CGFloat = -7.0
    static let pipeSpeed: CGFloat = 2.5 // This is a factor, actual speed is calculated as pipeSpeed * 60.0 points/sec

    static let pipeGap: CGFloat = 180.0
    static let verticalPaddingForPipes: CGFloat = 15.0
    static let pipeSpawnInterval: TimeInterval = 1.5

    struct AudioFiles {
        static let characterBaseNames = ["flappybird", "flappybird2", "flappybird3"]
        static func characterFile(at index: Int) -> String? {
            guard index >= 0 && index < characterBaseNames.count else { return nil }
            return characterBaseNames[index] + ".mp3"
        }
    }

    struct ImageNames {
        static let background = "background-day.png"
        static let ground = "ground_pixelated"
        static let pipe = "pipe.png"
        static let pipeInverted = "pipeinverted.png"
        
        static let bird1 = "flappybird.png"
        static let bird2 = "flappybird2.png"
        static let bird3 = "flappybird3.png"
        static let characterBirds = [bird1, bird2, bird3]
    }

    struct FontNames {
        static let main = "04b_19"
        static let fallback = "HelveticaNeue-Bold"
    }

    struct NodeNames {
        static let background = "background"
        static let ground = "ground"
        // static let bird = "bird" // Bird node isn't typically named in this fashion for lookup
        static let pipe = "pipe"
        static let scoreNode = "scoreNode"
        static let characterSelectionUI = "characterSelectionUI"
        static let characterPreviewPrefix = "characterPreview_"
        static let selectionBorder = "selectionBorder"
        static let startGameButton = "startGameButton"
        static let gameOverLabel = "gameOverLabel"
        static let finalScoreLabel = "finalScoreLabel"
        static let gameOverHighScoreLabel = "gameOverHighScoreLabel"
        static let newHighScoreLabel = "newHighScoreLabel"
        static let tapToStart = "tapToStartLabel" // If needed for identification
        static let score = "scoreLabel"           // If needed for identification
        static let highScore = "highScoreLabel"     // If needed for identification
    }

    struct UserDefaultsKeys {
        static let highScore = "HighScore"
    }

    struct ZPositions {
        static let background: CGFloat = -10
        static let ground: CGFloat = 1
        static let pipes: CGFloat = 5
        static let bird: CGFloat = 10
        static let scoreLabel: CGFloat = 20
        static let tapToStartLabel: CGFloat = 20
        static let characterSelectionLabel: CGFloat = 20 // For "Tap on a character..."
        // static let characterSelectionTitle: CGFloat = 20 // For "Choose Your Character" (commented out in original)
        static let characterPreview: CGFloat = 15
        static let startGameButton: CGFloat = 20
        static let gameOverUI: CGFloat = 30
        static let highScoreDisplay: CGFloat = 20 // For the general high score label
    }
}//
//  Constants.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

