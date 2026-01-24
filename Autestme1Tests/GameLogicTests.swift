//
//  GameLogicTests.swift
//  Autestme1Tests
//
//  Unit tests for GameLogic class
//

import XCTest
@testable import Autestme

final class GameLogicTests: XCTestCase {

    var sut: GameLogic!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = GameLogic(
            gameTime: 10,
            gameVersion: .shapes,
            colorMode: .fixed,
            displayRate: 3,
            player: "TestPlayer",
            numberOfShapes: 3
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        // Clean up test high scores
        UserDefaults.standard.removeObject(forKey: "highscore_TestPlayer_shapes")
        UserDefaults.standard.removeObject(forKey: "highscore_TestPlayer_letters")
        UserDefaults.standard.removeObject(forKey: "highscore_TestPlayer_numbers")
        UserDefaults.standard.removeObject(forKey: "highscore_Player1_shapes")
        UserDefaults.standard.removeObject(forKey: "highscore_Player2_shapes")
        try super.tearDownWithError()
    }

    // MARK: - High Score Tests

    func testHighScorePersistence() {
        // Given
        let player = "TestPlayer"
        let score = 42

        // When
        GameLogic.setHighScore(score, for: player, gameVersion: .shapes)
        let retrievedScore = GameLogic.getHighScore(for: player, gameVersion: .shapes)

        // Then
        XCTAssertEqual(retrievedScore, score, "High score should be persisted and retrieved correctly")
    }

    func testHighScoreForDifferentPlayers() {
        // Given
        let player1 = "Player1"
        let player2 = "Player2"

        // When
        GameLogic.setHighScore(100, for: player1, gameVersion: .shapes)
        GameLogic.setHighScore(200, for: player2, gameVersion: .shapes)

        // Then
        XCTAssertEqual(GameLogic.getHighScore(for: player1, gameVersion: .shapes), 100)
        XCTAssertEqual(GameLogic.getHighScore(for: player2, gameVersion: .shapes), 200)
    }

    func testHighScoreForDifferentGameVersions() {
        // Given
        let player = "TestPlayer"

        // When
        GameLogic.setHighScore(10, for: player, gameVersion: .shapes)
        GameLogic.setHighScore(20, for: player, gameVersion: .letters)
        GameLogic.setHighScore(30, for: player, gameVersion: .numbers)

        // Then
        XCTAssertEqual(GameLogic.getHighScore(for: player, gameVersion: .shapes), 10)
        XCTAssertEqual(GameLogic.getHighScore(for: player, gameVersion: .letters), 20)
        XCTAssertEqual(GameLogic.getHighScore(for: player, gameVersion: .numbers), 30)
    }

    func testHighScoreDefaultsToZero() {
        // Given
        let nonExistentPlayer = "NonExistentPlayer_\(UUID().uuidString)"

        // When
        let score = GameLogic.getHighScore(for: nonExistentPlayer, gameVersion: .shapes)

        // Then
        XCTAssertEqual(score, 0, "High score for non-existent player should default to 0")
    }

    // MARK: - Shape Generation Tests

    func testGenerateShapesReturnsCorrectCount() {
        // Given
        let count = 4

        // When
        let shapes = GameLogic.generateShapes(numberOfShapes: count)

        // Then
        XCTAssertEqual(shapes.count, count, "Generated shapes should match requested count")
    }

    func testGenerateShapesReturnsUniqueShapes() {
        // Given
        let count = 4

        // When
        let shapes = GameLogic.generateShapes(numberOfShapes: count)
        let uniqueShapes = Set(shapes)

        // Then
        XCTAssertEqual(uniqueShapes.count, shapes.count, "All generated shapes should be unique")
    }

    func testGenerateShapesHandlesMaxCount() {
        // Given
        let maxCount = ShapeType.allCases.count

        // When
        let shapes = GameLogic.generateShapes(numberOfShapes: maxCount)

        // Then
        XCTAssertEqual(shapes.count, maxCount, "Should be able to generate max number of shapes")
    }

    // MARK: - Random Shape Tests

    func testGetRandomShapeExcludesProvided() {
        // Given
        let shapes: [ShapeType] = [.dot, .circle, .square]
        let excludedShape = ShapeType.dot

        // When - Run multiple times to increase confidence
        for _ in 0..<50 {
            let result = GameLogic.getRandomShape(shapes: shapes, excluding: excludedShape)

            // Then
            XCTAssertNotEqual(result, excludedShape, "Excluded shape should not be returned")
        }
    }

    func testGetRandomShapeAvoidsRecentShapes() {
        // Given
        let shapes: [ShapeType] = [.dot, .circle, .square, .line]
        let recentShapes: [ShapeType] = [.dot, .circle]

        // When - Run multiple times to increase confidence
        for _ in 0..<50 {
            let result = GameLogic.getRandomShape(shapes: shapes, lastShapes: recentShapes)

            // Then
            XCTAssertFalse(recentShapes.contains(result), "Recent shapes should be avoided when possible")
        }
    }

    func testGetRandomShapeReturnsSingleShapeWhenOnlyOneAvailable() {
        // Given
        let shapes: [ShapeType] = [.dot]

        // When
        let result = GameLogic.getRandomShape(shapes: shapes)

        // Then
        XCTAssertEqual(result, .dot, "Should return the only available shape")
    }

    func testGetRandomShapeFallsBackWhenAllExcluded() {
        // Given
        let shapes: [ShapeType] = [.dot, .circle]
        let recentShapes: [ShapeType] = [.dot, .circle]

        // When
        let result = GameLogic.getRandomShape(shapes: shapes, lastShapes: recentShapes)

        // Then - Should still return a valid shape even when all are in recent
        XCTAssertTrue(shapes.contains(result), "Should return a valid shape from the available shapes")
    }

    // MARK: - Initialization Tests

    func testInitializationSetsCorrectDefaults() {
        // Given/When - sut is initialized in setUp

        // Then
        XCTAssertEqual(sut.gameTime, 10)
        XCTAssertEqual(sut.gameVersion, .shapes)
        XCTAssertEqual(sut.colorMode, .fixed)
        XCTAssertEqual(sut.displayRate, 3)
        XCTAssertEqual(sut.player, "TestPlayer")
        XCTAssertEqual(sut.numberOfItems, 3)
        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.remainingTime, 10)
    }

    func testInitializationGeneratesCorrectNumberOfShapes() {
        // Then
        XCTAssertEqual(sut.shapeType.count, 3, "Should generate the specified number of shapes")
    }

    // MARK: - Reset Tests

    func testResetClearsState() {
        // Given
        sut.score = 50
        sut.shapeCounts[.dot] = 5
        sut.letterCounts["A"] = 3
        sut.numberCounts[1] = 2

        // When
        sut.reset()

        // Then
        XCTAssertEqual(sut.score, 0, "Score should be reset to 0")
        XCTAssertTrue(sut.shapeCounts.isEmpty, "Shape counts should be cleared")
        XCTAssertTrue(sut.letterCounts.isEmpty, "Letter counts should be cleared")
        XCTAssertTrue(sut.numberCounts.isEmpty, "Number counts should be cleared")
        XCTAssertEqual(sut.gameTime, 10, "Game time should be reset to 10")
        XCTAssertEqual(sut.remainingTime, 10, "Remaining time should match game time")
    }

    // MARK: - Color Setup Tests

    func testSetupShapeColorsAssignsAllShapes() {
        // Then - shapeColors should have colors for all shape types
        for shape in ShapeType.allCases {
            XCTAssertNotNil(sut.shapeColors[shape], "Color should be assigned for \(shape)")
        }
    }

    func testSetupLetterColorsAssignsForNumberOfItems() {
        // Given
        let letterLogic = GameLogic(
            gameTime: 10,
            gameVersion: .letters,
            colorMode: .fixed,
            displayRate: 3,
            player: "TestPlayer",
            numberOfShapes: 5
        )

        // Then - Should have colors for first 5 letters
        let expectedLetters: [Character] = ["A", "B", "C", "D", "E"]
        for letter in expectedLetters {
            XCTAssertNotNil(letterLogic.letterColors[letter], "Color should be assigned for letter \(letter)")
        }
    }

    // MARK: - Equality Tests

    func testEqualityBasedOnGameID() {
        // Given
        let logic1 = GameLogic(
            gameTime: 10,
            gameVersion: .shapes,
            colorMode: .fixed,
            displayRate: 3,
            player: "Player",
            numberOfShapes: 3
        )
        let logic2 = logic1

        // Then
        XCTAssertEqual(logic1, logic2, "Same instance should be equal")
    }

    func testInequalityForDifferentInstances() {
        // Given
        let logic1 = GameLogic(
            gameTime: 10,
            gameVersion: .shapes,
            colorMode: .fixed,
            displayRate: 3,
            player: "Player",
            numberOfShapes: 3
        )
        let logic2 = GameLogic(
            gameTime: 10,
            gameVersion: .shapes,
            colorMode: .fixed,
            displayRate: 3,
            player: "Player",
            numberOfShapes: 3
        )

        // Then
        XCTAssertNotEqual(logic1, logic2, "Different instances should not be equal (different UUIDs)")
    }
}
