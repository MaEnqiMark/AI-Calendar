//
//  NetworkManager.swift
//  AI-Calendar
//
//  Created by Samuel Lao on 12/2/25.
//

import Foundation

enum NetworkError: String, Error {
    case networkError
    case invalidURL
}

let apiKey = "what's an api key"

class NetworkManager {
    static let instance = NetworkManager()
        
    // Use this instead if running backend locally
    let baseUrl = "https://api.openai.com"

    
    func parseDueDate(_ string: String) -> Date {
        // 1. Try full ISO8601
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: string) {
            return date
        }
        
        // 2. Try plain "yyyy-MM-dd"
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current   // or TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        
        if let date = df.date(from: string) {
            return date
        }
        
        // 3. Fallback
        return Date()
    }
    
    func analyzeTask(_ text: String) async throws -> TaskItem {
        guard let url = URL(string: "\(baseUrl)/v1/chat/completions") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let now = Date()
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = .current
        let isoNow = isoFormatter.string(from: now)
        
        let prettyFormatter = DateFormatter()
        prettyFormatter.locale = Locale.current
        prettyFormatter.timeZone = .current
        prettyFormatter.dateStyle = .full
        prettyFormatter.timeStyle = .short
        let prettyNow = prettyFormatter.string(from: now)
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "task_item",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "title": ["type": "string"],
                            "isCompleted": ["type": "boolean"],
                            "dueDate": ["type": "string", "format": "date-time"],
                            "priority": ["type": "string", "enum": ["Low", "Medium", "High"]],
                            "completedDate": ["type": ["string", "null"], "format": "date-time"],
                            "duration": ["type": "number"]
                        ],
                        "required": ["title", "isCompleted", "dueDate", "priority", "duration"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You analyze user-written tasks and convert them into a TaskItem JSON object following the schema exactly.
                    Dates must be full ISO8601 with time and Z, e.g., 2023-12-18T00:00:00Z. Duration is in integer seconds (that is, 900, not 900.0).
                    The user's current local date and time is \(prettyNow) (\(isoNow)).
                    Interpret relative phrases like "today", "tomorrow", "next week", etc. using this datetime.
                    """
                ],
                [
                    "role": "user",
                    "content": text
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print(response)
            throw NetworkError.networkError
        }
        
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let taskJSON = completion.choices.first!.message.content
        
        let dto = try JSONDecoder().decode(TaskItemDTO.self, from: Data(taskJSON.utf8))
        
        let task = TaskItem(
            title: dto.title,
            isCompleted: dto.isCompleted,
            dueDate: parseDueDate(dto.dueDate),
            priority: TaskPriority(rawValue: dto.priority) ?? .medium,
            completedDate: dto.completedDate.flatMap { parseDueDate($0) },
            duration: dto.duration
        )
                
        return task
    }

}

