import Foundation

/// Service to fetch the current AUT token price from QuickSwap/DEX APIs
@MainActor
class PriceService: ObservableObject {
    static let shared = PriceService()

    @Published var autPriceUSD: Double = 0.0
    @Published var autPriceEUR: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    // AUT token contract address on Polygon
    private let autContractAddress = "0x3a0DCDFf06f9a0Ad20f212224a5162F6fc0e344c"

    // USDC contract address on Polygon (for price reference)
    private let usdcContractAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"

    private init() {}

    /// Fetch the current AUT price
    func fetchPrice() async {
        isLoading = true
        errorMessage = nil

        do {
            // Use DexScreener API - free, no API key needed
            let urlString = "https://api.dexscreener.com/latest/dex/tokens/\(autContractAddress)"
            guard let url = URL(string: urlString) else {
                throw PriceError.invalidURL
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw PriceError.invalidResponse
            }

            let dexResponse = try JSONDecoder().decode(DexScreenerResponse.self, from: data)

            if let pair = dexResponse.pairs?.first {
                autPriceUSD = Double(pair.priceUsd ?? "0") ?? 0.0

                // Convert to EUR (approximate rate, could fetch real rate)
                await fetchEURPrice()

                lastUpdated = Date()
            } else {
                // If no pairs found, use the initial pool price
                autPriceUSD = 0.01  // Initial price from liquidity pool
                autPriceEUR = 0.0095
                lastUpdated = Date()
            }

        } catch {
            errorMessage = "Could not fetch price: \(error.localizedDescription)"
            // Fallback to initial pool price
            autPriceUSD = 0.01
            autPriceEUR = 0.0095
        }

        isLoading = false
    }

    /// Fetch EUR/USD exchange rate and convert
    private func fetchEURPrice() async {
        // Simple approximation: EUR is typically ~0.92-0.95 of USD
        // For production, use a proper forex API
        let eurUsdRate = 0.92
        autPriceEUR = autPriceUSD * eurUsdRate
    }

    /// Calculate value of tokens in EUR
    func calculateValue(tokenAmount: Int) -> Double {
        return Double(tokenAmount) * autPriceEUR
    }

    /// Calculate value of tokens in USD
    func calculateValueUSD(tokenAmount: Int) -> Double {
        return Double(tokenAmount) * autPriceUSD
    }

    /// Format price for display
    func formattedEURValue(tokenAmount: Int) -> String {
        let value = calculateValue(tokenAmount: tokenAmount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }

    /// Format USD value for display
    func formattedUSDValue(tokenAmount: Int) -> String {
        let value = calculateValueUSD(tokenAmount: tokenAmount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - API Response Models

struct DexScreenerResponse: Codable {
    let pairs: [DexPair]?
}

struct DexPair: Codable {
    let priceUsd: String?
    let priceNative: String?
    let volume: DexVolume?
    let liquidity: DexLiquidity?
}

struct DexVolume: Codable {
    let h24: Double?
}

struct DexLiquidity: Codable {
    let usd: Double?
}

// MARK: - Errors

enum PriceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from price API"
        case .decodingError:
            return "Could not decode price data"
        }
    }
}
