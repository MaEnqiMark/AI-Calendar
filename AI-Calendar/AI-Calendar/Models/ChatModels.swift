struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let index: Int
    let message: ChatMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct TaskItemDTO: Codable {
    let title: String
    let isCompleted: Bool
    let dueDate: String
    let priority: String
    let completedDate: String?
    let duration: Double
}
