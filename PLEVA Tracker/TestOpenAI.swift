import Foundation

// Configuration
let azureKey = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_KEY") as? String
let azureEndpoint = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_ENDPOINT") as? String
let azureDeployment = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_DEPLOYMENT") as? String
guard let azureKey = azureKey, !azureKey.isEmpty,
      let azureEndpoint = azureEndpoint, !azureEndpoint.isEmpty,
      let deploymentName = azureDeployment, !deploymentName.isEmpty else {
    print("Please set AZURE_OPENAI_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT in your Info.plist.")
    exit(1)
}
// Create the request
let url = URL(string: "\(azureEndpoint)/openai/deployments/\(deploymentName)/chat/completions?api-version=2024-02-15-preview")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("Bearer \(azureKey)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let requestBody: [String: Any] = [
    "messages": [
        ["role": "system", "content": "You are a test assistant."],
        ["role": "user", "content": "Respond with 'OK' if you receive this message."]
    ],
    "temperature": 0.7,
    "max_tokens": 50
]

request.httpBody = try! JSONSerialization.data(withJSONObject: requestBody)

// Create a semaphore to wait for the async task
let semaphore = DispatchSemaphore(value: 0)

// Make the request
print("Testing connection to Azure OpenAI...")
print("URL: \(url.absoluteString)")
print("API Key: \(azureKey)")
print("deploymentName: \(deploymentName)")

let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    defer { semaphore.signal() }
    
    if let error = error {
        print("Error: \(error.localizedDescription)")
        return
    }
    
    if let httpResponse = response as? HTTPURLResponse {
        print("HTTP Status Code: \(httpResponse.statusCode)")
    }
    
    if let data = data,
       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        print("\nResponse:")
        print(String(data: try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted), encoding: .utf8)!)
    } else if let data = data {
        print("\nRaw response:")
        print(String(data: data, encoding: .utf8) ?? "Could not decode response")
    }
}

// Start the request
task.resume()

// Wait for the request to complete
_ = semaphore.wait(timeout: .now() + 30)