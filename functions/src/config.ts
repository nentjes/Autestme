/**
 * Reward-claim limits. Keep these in sync with the client's actual game
 * mechanics — see StartScreen.swift `rangeForType` / ShapeType.allCases.
 * shapes: max 6, numbers: max 10, letters: max 26 correct answers per round.
 */
export const MAX_AUT_PER_CLAIM = 26;
export const MAX_AUT_PER_WALLET_PER_DAY = 130;
export const MAX_AUT_PER_DEVICE_PER_DAY = 130;
export const MAX_AUT_GLOBAL_PER_DAY = 5000;

export const POLYGON_CHAIN_ID = 137;
export const TOKEN_DECIMALS = 18;

/** Minimum priority fee tip Polygon requires for EIP-1559 inclusion. */
export const PRIORITY_FEE_GWEI = 30n;

/** Claims left "pending" longer than this are picked up by the reconciler. */
export const STUCK_CLAIM_TIMEOUT_MS = 5 * 60 * 1000;

export const ERC20_TRANSFER_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
];
