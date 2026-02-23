//
//  WatchScreenshotTests.swift
//  AutestmeWatch Watch AppUITests
//
//  Captures App Store screenshots for the Apple Watch app.
//

import XCTest

final class WatchScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use English locale for consistent screenshots
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(2)
    }

    @MainActor
    func testCaptureAllScreenshots() throws {
        // SCREENSHOT 1: Start Screen (top)
        saveScreenshot(name: "1-StartScreen-Top")

        // Scroll down to reveal more settings and the Start button
        app.swipeUp()
        sleep(1)

        // SCREENSHOT 2: Start Screen (scrolled, showing Start button)
        saveScreenshot(name: "2-StartScreen-StartButton")

        // Tap the Start button
        let startButton = app.buttons["Start the game"]
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
        } else {
            // Fallback: tap any visible button
            let buttons = app.buttons.allElementsBoundByIndex
            for btn in buttons {
                if btn.isHittable {
                    btn.tap()
                    break
                }
            }
        }
        sleep(2)

        // SCREENSHOT 3: Game Screen (shape being displayed)
        saveScreenshot(name: "3-GameScreen")

        // Wait for the game to end (default 5s + buffer)
        sleep(7)

        // SCREENSHOT 4: End Screen - Input phase (Digital Crown picker)
        saveScreenshot(name: "4-EndScreen-Input")

        // Try tapping the "Show results" button
        let showResultsButton = app.buttons["Results"]
        if showResultsButton.waitForExistence(timeout: 3) {
            showResultsButton.tap()
        } else {
            // Try to find any prominent button
            let allButtons = app.buttons.allElementsBoundByIndex
            for btn in allButtons {
                if btn.isHittable {
                    btn.tap()
                    break
                }
            }
        }
        sleep(2)

        // SCREENSHOT 5: End Screen - Results view
        saveScreenshot(name: "5-EndScreen-Results")
    }

    // MARK: - Helpers

    private func saveScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
