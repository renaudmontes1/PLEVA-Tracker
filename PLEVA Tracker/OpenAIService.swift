import Foundation

public enum OpenAIError: Error {
    case invalidAPIKey
    case invalidEndpoint
    case invalidResponse
    case networkError(Error)
}

public class OpenAIService {
    private let apiKey: String
    private let endpoint: String
    private let deploymentName: String
    private let useAzure: Bool
    
    public init() {
        if let azureKey = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_KEY") as? String,
           let azureEndpoint = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_ENDPOINT") as? String,
           let azureDeployment = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_DEPLOYMENT") as? String,
           !azureKey.isEmpty, !azureEndpoint.isEmpty, !azureDeployment.isEmpty {
            self.apiKey = azureKey
            self.endpoint = azureEndpoint
            self.deploymentName = azureDeployment
            self.useAzure = true
        } else if let openAIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
                  !openAIKey.isEmpty {
            self.apiKey = openAIKey
            self.endpoint = "https://api.openai.com/v1/chat/completions"
            self.deploymentName = ""
            self.useAzure = false
        } else {
            self.apiKey = ""
            self.endpoint = ""
            self.deploymentName = ""
            self.useAzure = false
            print("Warning: No valid OpenAI or Azure OpenAI configuration found in Info.plist")
        }
    }
    
    public func generateWeeklySummary(from entries: [DiaryEntry]) async throws -> String {
        guard !apiKey.isEmpty else { throw OpenAIError.invalidAPIKey }
        guard !endpoint.isEmpty else { throw OpenAIError.invalidEndpoint }
        
        let entriesText = formatEntriesForPrompt(entries)
        let prompt = """
        Analyze these PLEVA diary entries and provide a concise weekly summary focusing on:
        1. Overall trend in severity
        2. Most affected areas
        3. Key observations or patterns
        4. Recommendations based on the patterns

        Entries:
        \(entriesText)
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                ["role": "system", "content": "You are a medical diary analysis assistant specialized in PLEVA (Pityriasis Lichenoides et Varioliformis Acuta)."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        var url: URL
        if useAzure {
            // Azure OpenAI endpoint format
            url = URL(string: "\(endpoint)/openai/deployments/\(deploymentName)/chat/completions?api-version=2024-02-15-preview")!
        } else {
            // Regular OpenAI endpoint
            url = URL(string: endpoint)!
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if useAzure {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content
    }
    
    public func testConnection() async throws {
        guard !apiKey.isEmpty else { throw OpenAIError.invalidAPIKey }
        guard !endpoint.isEmpty else { throw OpenAIError.invalidEndpoint }
        
        // Create a simple test prompt
        let prompt = "Hello, this is a test message."
        
        // Prepare the request
        let url = URL(string: useAzure ? "\(endpoint)/openai/deployments/\(deploymentName)/chat/completions?api-version=2023-07-01-preview" : endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(useAzure ? "Bearer \(apiKey)" : "Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful assistant."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "messages": messages,
            "max_tokens": 50,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
        // If we get here, the connection was successful
    }
    
    private func formatEntriesForPrompt(_ entries: [DiaryEntry]) -> String {
        return entries.map { entry in
            """
            Date: \(entry.timestamp.formatted())
            Location: \(entry.location)
            Severity: \(entry.severity)
            Photos: \(entry.photos.count) photos attached
            Notes: \(entry.notes)
            """
        }.joined(separator: "\n\n")
    }
}
