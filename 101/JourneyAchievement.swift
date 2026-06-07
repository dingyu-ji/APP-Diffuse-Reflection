//
//  JourneyAchievement.swift
//  101
//
//  Created by 刘明 on 02/03/2026.
//

import SwiftUI
import RealityKit

struct JourneyAchievement: Identifiable, Codable {
    var id: UUID = UUID() // 唯一标识
    var storyText: String
    var paragraphs: [StoryParagraph]
    
    let photosData: [Data]        // UIImage -> Data，方便存储
    let modelNames: [String]      // 模型标识（这里存名字，真实文件可用URL等方式）
    let location: String          // 本次旅程的地点
    let trainThumbnailData: Data? // 车次缩略图，可选
    var date: Date = Date()       // 创建时间
    
    var scannedModelsInMemory: [ScannedModel]? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, storyText, paragraphs, photosData, modelNames, location, trainThumbnailData, date
    }
}
