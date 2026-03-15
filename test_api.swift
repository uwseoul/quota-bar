import Foundation

let apiKey = ProcessInfo.processInfo.environment["GLM_API_KEY"] ?? ""
let platform = ProcessInfo.processInfo.environment["GLM_PLATFORM"] ?? "https://api.z.ai"

print("Testing API for platform: \(platform)")
guard !apiKey.isEmpty else {
    print("Error: GLM_API_KEY environment variable is not set.")
    exit(1)
}

let url = URL(string: "\(platform)/api/monitor/usage/quota/limit")!
var request = URLRequest(url: url)
request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

let semaphore = DispatchSemaphore(value: 0)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("Network Error: \(error.localizedDescription)")
    } else if let data = data {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response:")
            print(jsonString)
        }
    }
    semaphore.signal()
}

task.resume()
semaphore.wait()
