import Foundation
import Combine

struct MiniMaxResponse: Codable {
    let modelRemains: [ModelRemain]
    let baseResp: BaseResp?

    enum CodingKeys: String, CodingKey {
        case modelRemains = "model_remains"
        case baseResp = "base_resp"
    }

    struct BaseResp: Codable {
        let statusCode: Int?
        let statusMsg: String?

        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case statusMsg = "status_msg"
        }
    }

    struct ModelRemain: Codable {
        let modelName: String
        let currentIntervalTotalCount: Int
        let currentIntervalUsageCount: Int
        let currentWeeklyTotalCount: Int
        let currentWeeklyUsageCount: Int
        let remainsTime: Int?
        let weeklyRemainsTime: Int?

        enum CodingKeys: String, CodingKey {
            case modelName = "model_name"
            case currentIntervalTotalCount = "current_interval_total_count"
            case currentIntervalUsageCount = "current_interval_usage_count"
            case currentWeeklyTotalCount = "current_weekly_total_count"
            case currentWeeklyUsageCount = "current_weekly_usage_count"
            case remainsTime = "remains_time"
            case weeklyRemainsTime = "weekly_remains_time"
        }
    }
}

struct MiniMaxFetcher: PlatformFetcher {
    let platformId: String = "minimax"

    func fetch(apiKey: String) -> AnyPublisher<[QuotaEntry], Error> {
        guard !apiKey.isEmpty else {
            return Fail(error: FetchError.missingAPIKey).eraseToAnyPublisher()
        }

        let endpoints = [
            "https://api.minimax.io/v1/token_plan/remains",
            "https://api.minimax.io/v1/api/openplatform/coding_plan/remains"
        ]

        return tryEndpoints(endpoints: endpoints, apiKey: apiKey, index: 0)
    }

    private func tryEndpoints(endpoints: [String], apiKey: String, index: Int) -> AnyPublisher<[QuotaEntry], Error> {
        guard index < endpoints.count else {
            return Fail(error: FetchError.api("All MiniMax endpoints failed")).eraseToAnyPublisher()
        }

        guard let url = URL(string: endpoints[index]) else {
            return tryEndpoints(endpoints: endpoints, apiKey: apiKey, index: index + 1)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    throw FetchError.api("HTTP \(httpResponse.statusCode)")
                }
                return data
            }
            .decode(type: MiniMaxResponse.self, decoder: JSONDecoder())
            .tryMap { response -> [QuotaEntry] in
                if let baseResp = response.baseResp, let code = baseResp.statusCode, code != 0 {
                    throw FetchError.api(baseResp.statusMsg ?? "MiniMax API error (code: \(code))")
                }

                let codingPlanModels = response.modelRemains.filter { model in
                    let name = model.modelName.lowercased()
                    return name.contains("coding") || name.contains("minimax-m")
                }

                let targetModel = codingPlanModels.first ?? response.modelRemains.first

                guard let model = targetModel else {
                    throw FetchError.api("MiniMax: 사용량 데이터를 포함한 모델을 찾을 수 없습니다.")
                }

                let used5hr = model.currentIntervalUsageCount
                let intervalTotal = model.currentIntervalTotalCount
                let usedWeekly = model.currentWeeklyUsageCount
                let weeklyTotal = model.currentWeeklyTotalCount

                let percent5hr = intervalTotal > 0 ? Double(used5hr) / Double(intervalTotal) : 0.0
                let percentWeekly = weeklyTotal > 0 ? Double(usedWeekly) / Double(weeklyTotal) : 0.0

                return [
                    QuotaEntry(
                        id: "minimax_5h",
                        platformId: "minimax",
                        name: "5H",
                        usagePercent: percent5hr,
                        usage: used5hr,
                        total: intervalTotal,
                        resetSeconds: model.remainsTime.map { $0 / 1000 },
                        totalDurationSeconds: 5 * 60 * 60
                    ),
                    QuotaEntry(
                        id: "minimax_weekly",
                        platformId: "minimax",
                        name: "Weekly",
                        usagePercent: percentWeekly,
                        usage: usedWeekly,
                        total: weeklyTotal,
                        resetSeconds: model.weeklyRemainsTime.map { $0 / 1000 },
                        totalDurationSeconds: 7 * 24 * 60 * 60
                    )
                ]
            }
            .catch { error -> AnyPublisher<[QuotaEntry], Error> in
                if index + 1 < endpoints.count {
                    return self.tryEndpoints(endpoints: endpoints, apiKey: apiKey, index: index + 1)
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
