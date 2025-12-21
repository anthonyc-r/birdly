//
//  FeedbackManager.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import UIKit
import AVFoundation

class FeedbackManager {
    // Singleton instance
    static let shared = FeedbackManager()
    
    // Retain audio players to prevent deallocation before playback completes
    private var correctPlayer: AVAudioPlayer?
    private var incorrectPlayer: AVAudioPlayer?
    
    // Private initializer to enforce singleton pattern
    private init() {
        preloadAudioFiles()
    }
    
    /// Preloads all required audio files during initialization
    private func preloadAudioFiles() {
        loadAudioFile(fileName: "Correct", fileExtension: "mp3", player: &correctPlayer)
        loadAudioFile(fileName: "Incorrect", fileExtension: "mp3", player: &incorrectPlayer)
    }
    
    /// Loads an audio file from the app bundle
    private func loadAudioFile(fileName: String, fileExtension: String, player: inout AVAudioPlayer?) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Could not find sound file: \(fileName).\(fileExtension)")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        } catch {
            print("Error loading sound file \(fileName).\(fileExtension): \(error)")
            player = nil
        }
    }
    
    /// Provides haptic and sound feedback for correct answers
    func playCorrectFeedback() {
        // Haptic feedback - success notification
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Sound feedback - play preloaded MP3 file
        playSound(player: &correctPlayer)
    }
    
    /// Provides haptic and sound feedback for incorrect answers
    func playIncorrectFeedback() {
        // Haptic feedback - error notification
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Sound feedback - play preloaded MP3 file
        playSound(player: &incorrectPlayer)
    }
    
    /// Plays a preloaded audio player
    private func playSound(player: inout AVAudioPlayer?) {
        guard let player = player else {
            print("Audio player not available")
            return
        }
        
        // Reset to beginning and play
        player.currentTime = 0
        player.play()
    }
}

