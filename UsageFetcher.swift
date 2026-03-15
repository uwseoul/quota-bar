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
                    self.lastError = "Parsing Error: \(error.localizedDescription)"
                    print("Decode Error: \(error)")
                }
            } receiveValue: { response in
                if response.code == 200 {
                    self.limits = response.data.limits
                } else {
                    self.lastError = response.msg
                }
            }
            .store(in: &cancellables)
    }
}
