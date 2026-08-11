//
//  Web3ManagerTests.swift
//  Autestme1Tests
//
//  Unit tests for Web3Manager address validation
//

import XCTest
import Web3Core
import FirebaseFunctions
@testable import Autestme

final class Web3ManagerTests: XCTestCase {

    // MARK: - Address Validation Tests

    func testAddressValidation_ValidAddress() {
        // Given
        let validAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"

        // Then
        XCTAssertTrue(validAddress.hasPrefix("0x"), "Valid address should start with 0x")
        XCTAssertEqual(validAddress.count, 42, "Valid address should be 42 characters")
    }

    func testAddressValidation_InvalidPrefix() {
        // Given
        let invalidAddress = "1x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"

        // Then
        XCTAssertFalse(invalidAddress.hasPrefix("0x"), "Address with wrong prefix should fail")
    }

    func testAddressValidation_WrongLength_TooShort() {
        // Given
        let shortAddress = "0x742d35Cc6634C0532925a3b844Bc9e"

        // Then
        XCTAssertNotEqual(shortAddress.count, 42, "Short address should not be valid length")
    }

    func testAddressValidation_WrongLength_TooLong() {
        // Given
        let longAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac123456"

        // Then
        XCTAssertNotEqual(longAddress.count, 42, "Long address should not be valid length")
    }

    func testAddressValidation_EmptyAddress() {
        // Given
        let emptyAddress = ""

        // Then
        XCTAssertFalse(emptyAddress.hasPrefix("0x"), "Empty address should fail prefix check")
        XCTAssertNotEqual(emptyAddress.count, 42, "Empty address should fail length check")
    }

    func testAddressValidation_OnlyPrefix() {
        // Given
        let prefixOnly = "0x"

        // Then
        XCTAssertTrue(prefixOnly.hasPrefix("0x"), "Should pass prefix check")
        XCTAssertNotEqual(prefixOnly.count, 42, "Should fail length check")
    }

    // MARK: - Address Format Tests

    func testAddressFormat_LowercaseHex() {
        // Given
        let lowercaseAddress = "0x742d35cc6634c0532925a3b844bc9e7595f3a1ac"

        // Then
        XCTAssertTrue(lowercaseAddress.hasPrefix("0x"))
        XCTAssertEqual(lowercaseAddress.count, 42)
    }

    func testAddressFormat_UppercaseHex() {
        // Given
        let uppercaseAddress = "0x742D35CC6634C0532925A3B844BC9E7595F3A1AC"

        // Then
        XCTAssertTrue(uppercaseAddress.hasPrefix("0x"))
        XCTAssertEqual(uppercaseAddress.count, 42)
    }

    func testAddressFormat_MixedCaseHex() {
        // Given - EIP-55 checksum format
        let mixedCaseAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"

        // Then
        XCTAssertTrue(mixedCaseAddress.hasPrefix("0x"))
        XCTAssertEqual(mixedCaseAddress.count, 42)
    }

    // MARK: - Validation Helper Function Tests

    func testIsValidEthereumAddress() {
        // Test helper function that mimics the validation in StartScreen
        func isValidEthereumAddress(_ address: String) -> Bool {
            return address.hasPrefix("0x") && address.count == 42
        }

        // Valid addresses
        XCTAssertTrue(isValidEthereumAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"))
        XCTAssertTrue(isValidEthereumAddress("0x0000000000000000000000000000000000000000"))

        // Invalid addresses
        XCTAssertFalse(isValidEthereumAddress(""))
        XCTAssertFalse(isValidEthereumAddress("0x"))
        XCTAssertFalse(isValidEthereumAddress("742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"))
        XCTAssertFalse(isValidEthereumAddress("0x742d35Cc"))
    }

    // MARK: - Web3Manager Singleton Tests

    @MainActor
    func testWeb3ManagerSharedInstanceExists() {
        // Given/When
        let manager = Web3Manager.shared

        // Then
        XCTAssertNotNil(manager, "Shared instance should exist")
    }

    @MainActor
    func testWeb3ManagerInitialState() {
        // Given
        let manager = Web3Manager.shared

        // Then - Check initial state (without modifying singleton)
        XCTAssertFalse(manager.isLoading, "Should not be loading initially")
        // Note: isConnected depends on previous state, so we don't assert on it
    }

    // MARK: - Recipient Address Tests

    @MainActor
    func testRecipientAddressCanBeSet() {
        // Given
        let manager = Web3Manager.shared
        let testAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"

        // Save original
        let originalAddress = manager.recipientAddress

        // When
        manager.recipientAddress = testAddress

        // Then
        XCTAssertEqual(manager.recipientAddress, testAddress)

        // Restore
        manager.recipientAddress = originalAddress
    }

    @MainActor
    func testRecipientAddressCanBeCleared() {
        // Given
        let manager = Web3Manager.shared

        // Save original
        let originalAddress = manager.recipientAddress

        // When
        manager.recipientAddress = ""

        // Then
        XCTAssertEqual(manager.recipientAddress, "")

        // Restore
        manager.recipientAddress = originalAddress
    }

    // MARK: - Status Message Tests

    @MainActor
    func testStatusMessageCanBeUpdated() {
        // Given
        let manager = Web3Manager.shared
        let testMessage = "Test status message"

        // Save original
        let originalMessage = manager.statusMessage

        // When
        manager.statusMessage = testMessage

        // Then
        XCTAssertEqual(manager.statusMessage, testMessage)

        // Restore
        manager.statusMessage = originalMessage
    }

    // MARK: - EthereumAddress format validation (used by StartScreen)
    //
    // This is defense-in-depth only — the authoritative EIP-55 checksum
    // check lives server-side (functions/src/validation.ts, ethers.getAddress()).

    func testEthereumAddressAcceptsWellFormedHexAddress() {
        XCTAssertNotNil(EthereumAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"))
    }

    func testEthereumAddressRejectsMalformedInput() {
        XCTAssertNil(EthereumAddress("not-an-address"))
        XCTAssertNil(EthereumAddress("0x123"))
        XCTAssertNil(EthereumAddress(""))
    }

    // MARK: - Reward claiming (server-side signing via claimReward)

    final class MockRewardClaimer: RewardClaiming {
        var callCount = 0
        var stubbedError: Error?
        var stubbedResponse = RewardClaimResponse(status: "sent", txHash: "0xabc123")

        func claim(recipient: String, amount: Int, gameId: UUID, deviceId: String) async throws -> RewardClaimResponse {
            callCount += 1
            if let stubbedError { throw stubbedError }
            return stubbedResponse
        }
    }

    private let testAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f3a1Ac"

    @MainActor
    func testRewardPlayer_SuccessUpdatesStatusAndLeavesNothingToRetry() async {
        let mock = MockRewardClaimer()
        let manager = Web3Manager(claimer: mock)
        manager.recipientAddress = testAddress

        await manager.rewardPlayer(amount: 5, gameId: UUID(), deviceId: "test-device")

        XCTAssertEqual(mock.callCount, 1)
        XCTAssertTrue(manager.statusMessage.contains("5 AUT sent"))

        await manager.retryPendingClaimIfAny(deviceId: "test-device")
        XCTAssertEqual(mock.callCount, 1, "a successful claim should leave nothing for the retry path to resubmit")
    }

    @MainActor
    func testRewardPlayer_TransientFailureIsRetriedOnRelaunch() async {
        let mock = MockRewardClaimer()
        mock.stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
        let manager = Web3Manager(claimer: mock)
        manager.recipientAddress = testAddress

        await manager.rewardPlayer(amount: 5, gameId: UUID(), deviceId: "test-device")
        XCTAssertEqual(mock.callCount, 1)

        mock.stubbedError = nil // server is reachable again
        await manager.retryPendingClaimIfAny(deviceId: "test-device")
        XCTAssertEqual(mock.callCount, 2, "a transient failure should leave a claim to retry on relaunch")
    }

    @MainActor
    func testRewardPlayer_ResourceExhaustedIsNotRetried() async {
        let mock = MockRewardClaimer()
        mock.stubbedError = NSError(
            domain: FunctionsErrorDomain,
            code: FunctionsErrorCode.resourceExhausted.rawValue
        )
        let manager = Web3Manager(claimer: mock)
        manager.recipientAddress = testAddress

        await manager.rewardPlayer(amount: 5, gameId: UUID(), deviceId: "test-device")
        XCTAssertEqual(mock.callCount, 1)
        XCTAssertTrue(manager.statusMessage.contains("Daily reward limit"))

        await manager.retryPendingClaimIfAny(deviceId: "test-device")
        XCTAssertEqual(mock.callCount, 1, "a definitive rejection should not be retried")
    }

    @MainActor
    func testRewardPlayer_RejectsMalformedRecipientBeforeCallingRelayer() async {
        let mock = MockRewardClaimer()
        let manager = Web3Manager(claimer: mock)
        manager.recipientAddress = "not-an-address"

        await manager.rewardPlayer(amount: 5, gameId: UUID(), deviceId: "test-device")

        XCTAssertEqual(mock.callCount, 0, "a malformed recipient should be rejected before calling the relayer")
    }

    @MainActor
    func testRewardPlayer_IgnoresZeroAmount() async {
        let mock = MockRewardClaimer()
        let manager = Web3Manager(claimer: mock)
        manager.recipientAddress = testAddress

        await manager.rewardPlayer(amount: 0, gameId: UUID(), deviceId: "test-device")

        XCTAssertEqual(mock.callCount, 0)
    }
}
