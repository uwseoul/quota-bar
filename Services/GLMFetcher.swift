import Combine
import Foundation

protocol PlatformFetcher {
    var platformId: String { get }
    func fetch(apiKey: String) -> AnyPublisher<[QuotaEntry], Error>
}

struct GLMFetcher: PlatformFetcher {
    let platformId = "glm"
    let platform: GLMPlatform

    init(platform: GLMPlatform) {
        self.platform = platform
    }

    func fetch(apiKey: String) -> AnyPublisher<[QuotaEntry], Error> {
        guard !apiKey.isEmpty else {
            return Fail(error: FetchError.missingAPIKey).eraseToAnyPublisher()
        }

        guard let url = URL(string: "\(platform.baseURL)/api/monitor/usage/quota/limit") else {
            return Fail(error: FetchError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\ .data)
            .decode(type: GLMUsageResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard response.code == 200 else {
                    throw FetchError.api(response.msg)
                }

                return (response.data.limits ?? []).map { $0.toQuotaEntry(platformId: platformId) }
            }
            .eraseToAnyPublisher()
    }
}

enum FetchError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key가 설정되지 않았습니다."
        case .invalidURL:
            return "Invalid request URL."
        case .api(let message):
            return message
        }
    }
}
