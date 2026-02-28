//
//  AppStoreScreenshots.swift
//  Autestme1UITests
//
//  Captures 5 App Store screenshots for the iPhone app.
//  Run on iPhone 16 Pro Max simulator (6.7") for correct App Store resolution.
//
//  Schermen:
//  1. StartScreen — overzicht van de app
//  2. Shapes game in progress
//  3. EndScreen — invulformulier (geen keyboard)
//  4. Letters game in progress
//  5. Leaderboard
//

import XCTest

final class AppStoreScreenshots: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(2)
    }

    @MainActor
    func testCaptureAll() throws {

        // ── SCREENSHOT 1: Start screen ──
        // Scroll net iets naar beneden zodat Game Type picker zichtbaar is
        app.swipeUp(velocity: .slow)
        sleep(1)
        save("01-StartScreen")

        // Scroll terug voor de Start-knop tap
        app.swipeDown(velocity: .slow)
        sleep(1)

        // ── SCREENSHOT 2: Shapes game ──
        startGame()
        sleep(3)
        save("02-ShapesGame")
        sleep(4) // wacht tot 5-seconden spel afloopt

        // ── SCREENSHOT 3: EndScreen (meteen, vóór keyboard) ──
        // Geef de UI 0.5s om te renderen maar tap NIETS aan (voorkomt keyboard)
        sleep(1)
        save("03-EndScreen")

        // Ga terug naar StartScreen via "Back" navigatie knop
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        // ── SCREENSHOT 4: Letters game ──
        selectGameType("Letters")
        startGame()
        sleep(3)
        save("04-LettersGame")
        sleep(4)

        // Terug naar StartScreen
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        // ── SCREENSHOT 5: Leaderboard ──
        let leaderboardBtn = app.buttons["Leaderboard"]
        if leaderboardBtn.waitForExistence(timeout: 3) {
            leaderboardBtn.tap()
            sleep(4) // wacht op Firebase data
            save("05-Leaderboard")
        }
    }

    // MARK: - Helpers

    private func startGame() {
        let btn = app.buttons["Start game"]
        if btn.waitForExistence(timeout: 3) { btn.tap() }
    }

    private func selectGameType(_ label: String) {
        let btn = app.buttons[label]
        if btn.waitForExistence(timeout: 2) { btn.tap(); sleep(1) }
    }

    private func save(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
