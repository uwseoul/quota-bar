import Combine
import Foundation

struct OpenCodeGoFetcher: PlatformFetcher {
    let platformId = "opencodego"

    func fetch(apiKey: String) -> AnyPublisher<[QuotaEntry], Error> {
        let parts = apiKey.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else {
            return Fail(error: FetchError.api("OpenCode Go: workspaceId:authCookie 형식으로 입력하세요.")).eraseToAnyPublisher()
        }

        let workspaceId = String(parts[0])
        let authCookie = String(parts[1])

        guard let url = URL(string: "https://opencode.ai/workspace/\(workspaceId)/go") else {
            return Fail(error: FetchError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.setValue("auth=\(authCookie)", forHTTPHeaderField: "Cookie")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("[OpenCodeGo] HTTP \(httpResponse.statusCode)")
                }
                return data
            }
            .tryMap { data -> [QuotaEntry] in
                guard let html = String(data: data, encoding: .utf8) else {
                    throw FetchError.api("Invalid HTML encoding")
                }
                print("[OpenCodeGo] HTML length: \(html.count)")
                if let snippet = html.range(of: "rollingUsage") {
                    let start = html.index(snippet.lowerBound, offsetBy: -20, limitedBy: html.startIndex) ?? html.startIndex
                    let end = html.index(snippet.upperBound, offsetBy: 200, limitedBy: html.endIndex) ?? html.endIndex
                    print("[OpenCodeGo] Snippet: \(String(html[start..<end]))")
                } else {
                    print("[OpenCodeGo] 'rollingUsage' not found in HTML")
                }
                return try Self.parseHTML(html)
            }
            .eraseToAnyPublisher()
    }

    private static func parseHTML(_ html: String) throws -> [QuotaEntry] {
        let rolling = extractUsage(from: html, label: "rollingUsage")
        let weekly = extractUsage(from: html, label: "weeklyUsage")
        let monthly = extractUsage(from: html, label: "monthlyUsage")

        var entries: [QuotaEntry] = []

        if let rolling = rolling {
            entries.append(QuotaEntry(
                id: "opencodego_rolling",
                platformId: "opencodego",
                name: "Rolling",
                usagePercent: Double(rolling.percent) / 100.0,
                usage: nil,
                total: nil,
                resetSeconds: rolling.resetInSec,
                totalDurationSeconds: 5 * 60 * 60
            ))
        }
        if let weekly = weekly {
            entries.append(QuotaEntry(
                id: "opencodego_weekly",
                platformId: "opencodego",
                name: "Weekly",
                usagePercent: Double(weekly.percent) / 100.0,
                usage: nil,
                total: nil,
                resetSeconds: weekly.resetInSec,
                totalDurationSeconds: 7 * 24 * 60 * 60
            ))
        }
        if let monthly = monthly {
            entries.append(QuotaEntry(
                id: "opencodego_monthly",
                platformId: "opencodego",
                name: "Monthly",
                usagePercent: Double(monthly.percent) / 100.0,
                usage: nil,
                total: nil,
                resetSeconds: monthly.resetInSec,
                totalDurationSeconds: 30 * 24 * 60 * 60
            ))
        }

        guard !entries.isEmpty else {
            throw FetchError.api("OpenCode Go 대시보드에서 사용량 데이터를 찾을 수 없습니다.")
        }

        return entries
    }

    private static func extractUsage(from html: String, label: String) -> (percent: Int, resetInSec: Int)? {
        let pattern = "\(label):\\s*(?:\\$R\\[\\d+\\]\\s*=\\s*)?\\{\\s*status:\\s*\"[^\"]+\",\\s*resetInSec:\\s*(\\d+),\\s*usagePercent:\\s*(\\d+)\\s*\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }

        guard let resetRange = Range(match.range(at: 1), in: html),
              let percentRange = Range(match.range(at: 2), in: html) else { return nil }

        let resetStr = String(html[resetRange])
        let percentStr = String(html[percentRange])

        guard let reset = Int(resetStr), let percent = Int(percentStr) else { return nil }
        return (percent, reset)
    }

}
