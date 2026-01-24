//
//  GameTimerTests.swift
//  Autestme1Tests
//
//  Unit tests for GameTimer class
//

import XCTest
@testable import Autestme

final class GameTimerTests: XCTestCase {

    var sut: GameTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = GameTimer(gameTime: 10, displayRate: 3)
    }

    override func tearDownWithError() throws {
        sut.stop()
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Then
        XCTAssertEqual(sut.remainingTime, 10, "Initial remaining time should match gameTime")
        XCTAssertFalse(sut.isRunning, "Timer should not be running initially")
    }

    func testInitWithDifferentValues() {
        // Given
        let timer = GameTimer(gameTime: 30, displayRate: 5)

        // Then
        XCTAssertEqual(timer.remainingTime, 30)
        XCTAssertFalse(timer.isRunning)

        // Cleanup
        timer.stop()
    }

    // MARK: - Start Tests

    func testStartSetsIsRunningTrue() {
        // When
        sut.start { }

        // Then
        XCTAssertTrue(sut.isRunning, "Timer should be running after start")
    }

    func testStartResetsRemainingTime() {
        // Given
        sut.start { }

        // Then - After starting, remaining time should be at initial value
        XCTAssertEqual(sut.remainingTime, 10, "Remaining time should be reset on start")
    }

    // MARK: - Stop Tests

    func testStopSetsIsRunningFalse() {
        // Given
        sut.start { }
        XCTAssertTrue(sut.isRunning)

        // When
        sut.stop()

        // Then
        XCTAssertFalse(sut.isRunning, "Timer should not be running after stop")
    }

    func testStopWhenNotRunning() {
        // Given - Timer is not running
        XCTAssertFalse(sut.isRunning)

        // When
        sut.stop()

        // Then - Should not crash, still not running
        XCTAssertFalse(sut.isRunning)
    }

    // MARK: - Reset Tests

    func testResetUpdatesRemainingTime() {
        // Given
        sut.start { }

        // When
        sut.reset(gameTime: 20, displayRate: 5)

        // Then
        XCTAssertEqual(sut.remainingTime, 20, "Remaining time should be updated to new gameTime")
        XCTAssertFalse(sut.isRunning, "Timer should be stopped after reset")
    }

    func testResetStopsTimer() {
        // Given
        sut.start { }
        XCTAssertTrue(sut.isRunning)

        // When
        sut.reset(gameTime: 15, displayRate: 2)

        // Then
        XCTAssertFalse(sut.isRunning, "Timer should stop on reset")
    }

    // MARK: - Timer Countdown Tests

    func testTimerDecrementsRemainingTime() {
        // Given
        let expectation = XCTestExpectation(description: "Timer decrements")

        // When
        sut.start { }

        // Then - Wait for timer to decrement
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertLessThan(self.sut.remainingTime, 10, "Remaining time should decrement")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testTimerStopsAtZero() {
        // Given
        let shortTimer = GameTimer(gameTime: 2, displayRate: 1)
        let expectation = XCTestExpectation(description: "Timer stops at zero")

        // When
        shortTimer.start { }

        // Then - Wait for timer to reach zero
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertFalse(shortTimer.isRunning, "Timer should stop when reaching zero")
            XCTAssertLessThanOrEqual(shortTimer.remainingTime, 0, "Remaining time should be zero or less")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        shortTimer.stop()
    }

    // MARK: - Callback Tests

    func testShapeDisplayCallbackIsCalled() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        var callCount = 0

        // When
        sut.start {
            callCount += 1
            if callCount >= 2 {
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertGreaterThanOrEqual(callCount, 2, "Callback should be called multiple times")
    }

    // MARK: - Multiple Start/Stop Cycles

    func testMultipleStartStopCycles() {
        // First cycle
        sut.start { }
        XCTAssertTrue(sut.isRunning)
        sut.stop()
        XCTAssertFalse(sut.isRunning)

        // Second cycle
        sut.start { }
        XCTAssertTrue(sut.isRunning)
        sut.stop()
        XCTAssertFalse(sut.isRunning)
    }
}
