//
//  AIManager.swift
//  101
//
//  Created by 刘明 on 05/03/2026.
//

import Foundation

class AIManager {
    static let shared = AIManager()
    private init() {}

    // 生成故事
    func generateStory(from text: String) async -> String {
        // Dify API endpoint
        guard let url = URL(string: "https://api.dify.ai/v1/completion-messages") else {
            return "API 地址无效"
        }

        // 你的 Dify API Key
        let apiKey = "app-cTMXcE52xz3P31xN1uybq9Gr"

        // 请求体
        let requestBody: [String: Any] = [
            "inputs": ["query": text],       // 传给模型的文本
            "response_mode": "blocking",      // 或 "streaming" 根据你的需求
            "user": "your_user_id"           // 可选，用于区分用户
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return "JSON 序列化失败"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            // 直接尝试把返回数据解析成 JSON
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["answer"] as? String {
                return answer
            } else if let raw = String(data: data, encoding: .utf8) {
                // 如果结构和预期不符，返回原始文本，方便调试
                return "返回内容解析失败，原始数据：\n\(raw)"
            } else {
                return "返回内容解析失败"
            }
        } catch {
            return "请求 AI 失败: \(error.localizedDescription)"
        }
    }
}


