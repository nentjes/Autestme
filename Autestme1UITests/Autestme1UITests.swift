//
//  Autestme1UITests.swift
//  Autestme1UITests
//
//  UI Tests for Autestme app
//

import XCTest

final class Autestme1UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the app launches and shows the start screen
        XCTAssertTrue(app.staticTexts["Autestme"].waitForExistence(timeout: 5))
    }
}
