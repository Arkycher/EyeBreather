import XCTest
@testable import EyeBreather

@MainActor
final class SoundManagerTests: XCTestCase {
    
    override func tearDown() {
        SettingsManager.shared.settings.enableSound = true
        super.tearDown()
    }
    
    func testAvailableSoundsNotEmpty() {
        XCTAssertFalse(SoundManager.availableSounds.isEmpty)
    }
    
    func testAvailableSoundsContainsDefault() {
        let hasDefault = SoundManager.availableSounds.contains { $0.id == "default" }
        XCTAssertTrue(hasDefault)
    }
    
    func testPlayBreakStartSoundWhenDisabled() {
        SettingsManager.shared.settings.enableSound = false
        SoundManager.shared.playBreakStartSound()
        // Should not crash
    }
    
    func testPlayBreakEndSoundWhenDisabled() {
        SettingsManager.shared.settings.enableSound = false
        SoundManager.shared.playBreakEndSound()
        // Should not crash
    }
    
    func testPlayBreakStartSoundWhenEnabled() {
        SettingsManager.shared.settings.enableSound = true
        SettingsManager.shared.settings.breakStartSound = "glass"
        SoundManager.shared.playBreakStartSound()
        // Should not crash
    }
    
    func testAllSoundIdsPlayWithoutCrash() {
        SettingsManager.shared.settings.enableSound = true
        for sound in SoundManager.availableSounds {
            SettingsManager.shared.settings.breakStartSound = sound.id
            SoundManager.shared.playBreakStartSound()
        }
    }
}
