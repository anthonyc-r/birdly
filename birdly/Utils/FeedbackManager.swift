//
//  FeedbackManager.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import UIKit
import AVFoundation
import CoreHaptics

class FeedbackManager {
    // Singleton instance
    static let shared = FeedbackManager()
    
    // Retain audio players to prevent deallocation before playback completes
    private var correctPlayer: AVAudioPlayer?
    private var incorrectPlayer: AVAudioPlayer?
    
    // Pre-prepared haptic generators for optimal performance
    private let selectionGenerator: UIImpactFeedbackGenerator
    
    // CHHapticEngine for advanced haptic patterns
    private var hapticEngine: CHHapticEngine?
    
    // Private initializer to enforce singleton pattern
    private init() {
        // Initialize haptic generator for simple selection feedback
        selectionGenerator = UIImpactFeedbackGenerator(style: .light)
        selectionGenerator.prepare()
        
        // Initialize CHHapticEngine for advanced haptic patterns
        initializeHapticEngine()
        
        preloadAudioFiles()
    }
    
    /// Initializes the CHHapticEngine for advanced haptic patterns
    private func initializeHapticEngine() {
        // Check if device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device does not support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            
            // Set up engine stopped handler
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                // Try to restart the engine
                self?.restartHapticEngine()
            }
            
            // Set up engine reset handler
            hapticEngine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                // Try to restart the engine
                self?.restartHapticEngine()
            }
            
            // Start the engine
            try hapticEngine?.start()
        } catch {
            print("Error creating haptic engine: \(error)")
            hapticEngine = nil
        }
    }
    
    /// Restarts the haptic engine if it stops
    private func restartHapticEngine() {
        guard let engine = hapticEngine else { return }
        
        do {
            try engine.start()
        } catch {
            print("Error restarting haptic engine: \(error)")
        }
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
    /// Uses a strong rising pattern: medium → heavy → success notification (~1s total)
    func playCorrectFeedback() {
        // Create haptic pattern for correct feedback (rising pattern)
        createCorrectHapticPattern()
        
        // Sound feedback - play preloaded MP3 file
        playSound(player: &correctPlayer)
    }
    
    /// Creates and plays the correct answer haptic pattern using CHHapticPattern
    private func createCorrectHapticPattern() {
        guard let engine = hapticEngine else {
            // Fallback to simple notification if engine unavailable
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            return
        }
        
        // Create events for rising pattern: medium → heavy → success
        var events: [CHHapticEvent] = []
        
        // Medium impact at 0.0s (intensity 0.5, sharpness 0.5)
        let mediumImpact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0.0
        )
        events.append(mediumImpact)
        
        // Heavy impact at 0.2s (intensity 0.8, sharpness 0.6)
        let heavyImpact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.2
        )
        events.append(heavyImpact)
        
        // Success notification at 0.5s (intensity 1.0, sharpness 0.8)
        let successNotification = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0.5
        )
        events.append(successNotification)
        
        // Create pattern and play
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Error playing correct haptic pattern: \(error)")
            // Fallback to simple notification
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
    
    /// Provides haptic and sound feedback for incorrect answers
    /// Uses a strong descending pattern: heavy → medium → light → error notification (~1s total)
    func playIncorrectFeedback() {
        // Create haptic pattern for incorrect feedback (descending pattern)
        createIncorrectHapticPattern()
        
        // Sound feedback - play preloaded MP3 file
        playSound(player: &incorrectPlayer)
    }
    
    /// Creates and plays the incorrect answer haptic pattern using CHHapticPattern
    private func createIncorrectHapticPattern() {
        guard let engine = hapticEngine else {
            // Fallback to simple notification if engine unavailable
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
            return
        }
        
        // Create events for descending pattern: heavy → medium → light → error
        var events: [CHHapticEvent] = []
        
        // Heavy impact at 0.0s (intensity 0.8, sharpness 0.6)
        let heavyImpact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.0
        )
        events.append(heavyImpact)
        
        // Medium impact at 0.15s (intensity 0.5, sharpness 0.5)
        let mediumImpact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0.15
        )
        events.append(mediumImpact)
        
        // Light impact at 0.3s (intensity 0.3, sharpness 0.4)
        let lightImpact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ],
            relativeTime: 0.3
        )
        events.append(lightImpact)
        
        // Error notification at 0.6s (intensity 0.9, sharpness 0.7)
        let errorNotification = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: 0.6
        )
        events.append(errorNotification)
        
        // Create pattern and play
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Error playing incorrect haptic pattern: \(error)")
            // Fallback to simple notification
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }
    
    /// Provides a simple, short haptic feedback for button presses and interactions
    /// Uses a light impact for subtle, responsive feedback
    func playSelectionFeedback() {
        selectionGenerator.prepare()
        selectionGenerator.impactOccurred()
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

