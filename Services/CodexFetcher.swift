import Combine
import Foundation

struct CodexFetcher: PlatformFetcher {
    let platformId = "codex"

    func fetch(apiKey: String) -> AnyPublisher<[QuotaEntry], Error> {
        let authURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json")

        guard let data = try? Data(contentsOf: authURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              let accountId = tokens["account_id"] as? String else {
            return Fail(error: FetchError.missingAPIKey).eraseToAnyPublisher()
        }

        guard let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else {
            return Fail(error: FetchError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: CodexUsageResponse.self, decoder: JSONDecoder())
            .map { response in
                var entries: [QuotaEntry] = []
                let now = Int(Date().timeIntervalSince1970)

                if let primary = response.rateLimit?.primaryWindow {
                    let resetSeconds = primary.resetAt - now
                    entries.append(QuotaEntry(
                        id: "codex_5h",
                        platformId: platformId,
                        name: "5H",
                        usagePercent: Double(primary.usedPercent) / 100.0,
                        usage: nil,
                        total: nil,
                        resetSeconds: resetSeconds > 0 ? resetSeconds : nil,
                        speedStatus: Self.calculateSpeedStatus(
                            usedPercent: Double(primary.usedPercent) / 100.0,
                            resetAt: primary.resetAt,
                            windowSeconds: primary.limitWindowSeconds
                        )
                    ))
                }

                if let secondary = response.rateLimit?.secondaryWindow {
                    let resetSeconds = secondary.resetAt - now
                    entries.append(QuotaEntry(
                        id: "codex_7d",
                        platformId: platformId,
                        name: "7D",
                        usagePercent: Double(secondary.usedPercent) / 100.0,
                        usage: nil,
                        total: nil,
                        resetSeconds: resetSeconds > 0 ? resetSeconds : nil,
                        speedStatus: Self.calculateSpeedStatus(
                            usedPercent: Double(secondary.usedPercent) / 100.0,
                            resetAt: secondary.resetAt,
                            windowSeconds: secondary.limitWindowSeconds
                        )
                    ))
                }

                if let codeReview = response.codeReviewRateLimit?.primaryWindow {
                    let resetSeconds = codeReview.resetAt - now
                    entries.append(QuotaEntry(
                        id: "codex_review",
                        platformId: platformId,
                        name: "Review",
                        usagePercent: Double(codeReview.usedPercent) / 100.0,
                        usage: nil,
                        total: nil,
                        resetSeconds: resetSeconds > 0 ? resetSeconds : nil,
                        speedStatus: Self.calculateSpeedStatus(
                            usedPercent: Double(codeReview.usedPercent) / 100.0,
                            resetAt: codeReview.resetAt,
                            windowSeconds: codeReview.limitWindowSeconds
                        )
                    ))
                }

                return entries
            }
            .eraseToAnyPublisher()
    }

    private static func calculateSpeedStatus(usedPercent: Double, resetAt: Int, windowSeconds: Int) -> SpeedStatus {
        let now = Int(Date().timeIntervalSince1970)
        let remaining = resetAt - now

        if remaining <= 0 {
            return .normal
        }

        let totalDuration = windowSeconds
        let elapsed = totalDuration - remaining
        let elapsedPercent = Double(elapsed) / Double(totalDuration)

        if elapsedPercent < 0.01 {
            return .normal
        }

        let speedRatio = usedPercent / elapsedPercent

        if speedRatio > 1.3 {
            return .fast
        } else if speedRatio < 0.7 {
            return .slow
        } else {
            return .normal
        }
    }
}

struct CodexUsageResponse: Codable {
    let planType: String?
    let rateLimit: CodexRateLimitContainer?
    let codeReviewRateLimit: CodexRateLimitContainer?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case codeReviewRateLimit = "code_review_rate_limit"
    }
}

struct CodexRateLimitContainer: Codable {
    let primaryWindow: CodexWindow?
    let secondaryWindow: CodexWindow?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexWindow: Codable {
    let usedPercent: Int
    let resetAt: Int
    let limitWindowSeconds: Int

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case resetAt = "reset_at"
        case limitWindowSeconds = "limit_window_seconds"
    }
}