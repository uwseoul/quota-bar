import Combine
import Foundation

@MainActor
final class UsageFetcher: ObservableObject {
    @Published var entries: [QuotaEntry] = []
    @Published var perPlatformResults: [String: PlatformResult] = [:]
    @Published var isLoading = false
    @Published var lastError: String?

    private var cancellables = Set<AnyCancellable>()

    var limits: [GLMLimit] {
        entries
            .filter { $0.platformId == "glm" }
            .map { entry in
                let typeUnit = Self.legacyTypeAndUnit(for: entry.name)
                let total = entry.total ?? entry.usage
                let remaining = total.flatMap { totalValue in
                    entry.usage.map { max(totalValue - $0, 0) }
                }
                let nextResetTime = entry.resetSeconds.map {
                    Int64(Date().timeIntervalSince1970 * 1000) + Int64($0 * 1000)
                }

                return GLMLimit(
                    type: typeUnit.type,
                    unit: typeUnit.unit,
                    number: total,
                    percentage: Int((entry.usagePercent * 100).rounded()),
                    nextResetTime: nextResetTime,
                    usage: entry.usage,
                    remaining: remaining
                )
            }
    }

    func fetch(apiKey: String, platform: GLMPlatform) {
        let storage = Storage()
        storage.apiKey = apiKey
        storage.apiKeys["glm"] = apiKey
        storage.selectedPlatform = platform
        storage.enabledPlatforms["glm"] = true
        fetchAll(storage: storage)
    }

    func fetchAll(storage: Storage) {
        cancellables.removeAll()

        var activePublishers: [AnyPublisher<(String, Result<[QuotaEntry], Error>), Never>] = []
        var nextResults: [String: PlatformResult] = [:]

        let platforms: [(String, PlatformFetcher)] = [
            ("glm", GLMFetcher(platform: storage.selectedPlatform)),
            ("minimax", MiniMaxFetcher()),
            ("codex", CodexFetcher()),
            ("opencodego", OpenCodeGoFetcher())
        ]

        for (platformId, fetcher) in platforms {
            if storage.isPlatformEnabled(platformId) {
                nextResults[platformId] = PlatformResult(entries: [], error: nil, isLoading: true)

                let publisher = fetcher
                    .fetch(apiKey: storage.apiKey(for: platformId))
                    .map { (platformId, Result<[QuotaEntry], Error>.success($0)) }
                    .catch { Just((platformId, Result<[QuotaEntry], Error>.failure($0))) }
                    .eraseToAnyPublisher()

                activePublishers.append(publisher)
            } else {
                nextResults[platformId] = PlatformResult(entries: [], error: nil, isLoading: false)
            }
        }

        perPlatformResults = nextResults
        entries = []
        isLoading = !activePublishers.isEmpty
        lastError = nil

        guard !activePublishers.isEmpty else {
            return
        }

        Publishers.MergeMany(activePublishers)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self else { return }

                var updatedResults = self.perPlatformResults
                var aggregatedEntries: [QuotaEntry] = []
                var firstError: String?

                for (platformId, result) in results {
                    switch result {
                    case .success(let platformEntries):
                        aggregatedEntries.append(contentsOf: platformEntries)
                        updatedResults[platformId] = PlatformResult(entries: platformEntries, error: nil, isLoading: false)
                    case .failure(let error):
                        let message = Self.format(error: error)
                        updatedResults[platformId] = PlatformResult(entries: [], error: message, isLoading: false)
                        if firstError == nil {
                            firstError = message
                        }
                    }
                }

                self.entries = aggregatedEntries.sorted(by: Self.sortEntries)
                self.perPlatformResults = updatedResults
                self.lastError = firstError
                self.isLoading = false
                NotificationCenter.default.post(name: NSNotification.Name("UsageUpdated"), object: nil)
            }
            .store(in: &cancellables)
    }

    static func sortEntries(lhs: QuotaEntry, rhs: QuotaEntry) -> Bool {
        if lhs.platformId != rhs.platformId {
            return lhs.platformId < rhs.platformId
        }

        return sortRank(for: lhs.name) < sortRank(for: rhs.name)
    }

    private static func sortRank(for name: String) -> Int {
        if name.contains("5 Hours") { return 0 }
        if name.contains("Weekly") { return 1 }
        if name.contains("Monthly") { return 2 }
        return 99
    }

    private static func legacyTypeAndUnit(for name: String) -> (type: String?, unit: Int?) {
        if name.contains("5 Hours") {
            return ("TOKENS_LIMIT", 3)
        }

        if name.contains("Weekly") {
            return ("TOKENS_LIMIT", 6)
        }

        if name.contains("Monthly") {
            return ("TIME_LIMIT", 5)
        }

        return (nil, nil)
    }

    private static func format(error: Error) -> String {
        if let fetchError = error as? FetchError,
           let message = fetchError.errorDescription {
            return message
        }

        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, _):
                return "Parsing Error: Missing field: \(key.stringValue)"
            case .typeMismatch(let type, let context):
                let path = context.codingPath.map(\.stringValue).joined(separator: ".")
                return "Parsing Error: Type mismatch: \(type) at \(path)"
            case .valueNotFound(let type, let context):
                let path = context.codingPath.map(\.stringValue).joined(separator: ".")
                return "Parsing Error: Value not found: \(type) at \(path)"
            case .dataCorrupted(let context):
                return "Parsing Error: Data corrupted: \(context.debugDescription)"
            @unknown default:
                break
            }
        }

        return error.localizedDescription
    }
}
