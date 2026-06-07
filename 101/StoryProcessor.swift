//
//  StoryProcessor.swift
//  101
//
//  Created by 刘明 on 08/03/2026.
//

import Foundation
import NaturalLanguage

struct StoryParagraph: Identifiable, Codable {
    var id: UUID = UUID()
    let text: String
    let words: [String]
    var matchedImage: String? = nil
}

struct StoryProcessor {

    static func process(text: String) -> [StoryParagraph] {
        // 按句号分段
        let parts = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }

        return parts.map { paragraph in
            let words = segment(paragraph)
            return StoryParagraph(
                text: paragraph,
                words: words
            )
        }
    }

    
    // 中文分词函数
        static func segment(_ text: String) -> [String] {
            var result: [String] = []

            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = text

            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                let word = String(text[range])
                // 去掉空白字符
                if !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append(word)
                }
                return true
            }

            return result
        }
    
    
}
