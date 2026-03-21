import Foundation
import Combine

class UsageFetcher: ObservableObject {
    @Published var limits: [GLMLimit] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetch(apiKey: String, platform: GLMPlatform) {
        guard !apiKey.isEmpty else {
            self.lastError = "API Key가 설정되지 않았습니다."
            return
        }
        
        isLoading = true
        lastError = nil
        
        let url = URL(string: "\(platform.baseURL)/api/monitor/usage/quota/limit")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response in
                if let json = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(json)")
                }
                return data
            }
            .decode(type: GLMUsageResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    var detail = error.localizedDescription
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, _): detail = "Missing field: \(key.stringValue)"
                        case .typeMismatch(let type, let context): detail = "Type mismatch: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                        case .valueNotFound(let type, let context): detail = "Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                        case .dataCorrupted(let context): detail = "Data corrupted: \(context.debugDescription)"
                        @unknown default: break
                        }
                    }
                    self.lastError = "Parsing Error: \(detail)"
                    print("Decode Error: \(error)")
                }
            }             receiveValue: { response in
                if response.code == 200 {
                    self.limits = response.data.limits ?? []
                } else {
                    self.lastError = response.msg
                }
                NotificationCenter.default.post(name: NSNotification.Name("UsageUpdated"), object: nil)
            }
            .store(in: &cancellables)
    }
}
