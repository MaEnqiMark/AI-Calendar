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

let apiKey = "what api key"

class NetworkManager {
    static let instance = NetworkManager()
        
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
    
    func roundDuration(_ value: Double) -> Double {
        let allowed = [900.0, 1800.0, 2700.0, 5400.0, 7200.0]
        return allowed.min(by: { abs($0 - value) < abs($1 - value) })!
    }
    
    func analyzeTask(_ text: String) async throws -> TaskItem? {
        guard let url = URL(string: "\(baseUrl)/v1/chat/completions") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let now = Date()
        let timeZone = TimeZone.current
        let timeZoneIdentifier = timeZone.identifier
        let timeZoneAbbreviation = timeZone.abbreviation() ?? timeZoneIdentifier
                
        
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
                            "duration": [
                                "type": "number",
                                "enum": [900, 1800, 2700, 5400, 7200]
                            ]
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
                    Duration is in integer seconds and MUST be one of the allowed enums: 900, 1800, 2700, 5400, 7200.
                    ROUND TO THE NEAREST ENUM (ex. 18000 -> 7200). DO NOT DEVIATE FROM THESE ENUMS.
                    The user's current local date and time is \(prettyNow) (\(isoNow)).
                    The user's IANA time zone is \(timeZoneIdentifier) (\(timeZoneAbbreviation)).
                    Interpret relative phrases like "today", "tomorrow", "next week", etc. using this datetime.
                    Dates must be full ISO8601 with time and Z, e.g., 2023-12-18T00:00:00Z. Ensure that the date is relevative to the user's time zone. Translate the hours as necessary.
                    
                    (ex. If it says 'due Tuesday', the user's timezone is EST, and Tuesday is December 9th, return 2025-12-09T05:00:00Z to account for the time change to EST.)
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
            throw NetworkError.networkError
        }
        
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let taskJSON = completion.choices.first!.message.content
        
        do {
            let dto = try JSONDecoder().decode(TaskItemDTO.self, from: Data(taskJSON.utf8))
            
            let task = TaskItem(
                title: dto.title,
                isCompleted: dto.isCompleted,
                dueDate: parseDueDate(dto.dueDate),
                priority: TaskPriority(rawValue: dto.priority) ?? .medium,
                completedDate: dto.completedDate.flatMap { parseDueDate($0) },
                duration: self.roundDuration(dto.duration)
            )
                    
            return task
        } catch {
            return nil
        }
        
    }
}

