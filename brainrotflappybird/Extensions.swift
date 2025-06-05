import SpriteKit
import UIKit // For UIImage

// Helper extension for SKTexture
extension SKTexture {
    convenience init?(optionalImageNamed name: String) {
        // Check if the image actually exists in the assets or bundle
        if UIImage(named: name) != nil {
            self.init(imageNamed: name)
        } else {
            print("SKTEXTURE WARNING: Texture image named '\(name)' not found in bundle.")
            return nil
        }
    }
}//
//  Extensions.swift
//  brainrotflappybird
//
//  Created by Sahil Prasad on 05/06/25.
//

