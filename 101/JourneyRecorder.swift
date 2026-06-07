//
//  JourneyRecorder.swift
//  101
//
//  Created by 刘明 on 28/02/2026.
//

import SwiftUI
import RealityKit

struct ScannedModel: Identifiable {
    let id = UUID()
    let name: String
    //var rootEntity: ModelEntity // 保存整个拼好的模型
}

class JourneyRecorder: ObservableObject {
    
    @AppStorage("totalPhotos") var totalPhotos: Int = 0
    @AppStorage("totalScans") var totalScans: Int = 0
    @AppStorage("totalViews") var totalViews: Int = 0
    @AppStorage("journeyCount") var journeyCount: Int = 0 // 0, 1, 2
    
    // 存储已解锁的气质 ID (如 "1,2,4")
    @AppStorage("unlockedTemperaments") var unlockedIDs: String = ""
    
    @Published var actions: [String] = []
    @Published var photos: [UIImage] = []

    // ⚠️ 不再保存 rootEntity
    @Published var scannedModels: [ScannedModel] = []

    @Published var achievements: [JourneyAchievement] = []

    init() {
        loadAchievementsFromDisk()
    }

    // 记录操作日志
    func recordAction(_ action: String) {
        actions.append(action)
        print("记录动作: \(action)")
    }

    // 记录拍照
    func recordPhoto(_ photo: UIImage) {
        photos.append(photo)
        totalPhotos += 1
        recordAction("拍照")
    }

    // 记录用户扫描了某个 target image
    func recordScannedImage(_ imageName: String) {
        // 已存在就跳过
        if scannedModels.contains(where: { $0.name == imageName }) { return }

        let model = ScannedModel(name: imageName)
        scannedModels.append(model)
        totalScans += 1
        recordAction("扫描：\(imageName)")
    }
    
    func recordViewIntroduction() {
            totalViews += 1
            recordAction("看介绍")
        }

        // --- 核心判定逻辑 ---
        func judgeTemperament() -> Int? {
            journeyCount += 1
            
            // 只有第3次旅程才触发判定
            guard journeyCount >= 3 else { return nil }
            
            let p = totalPhotos
            let s = totalScans
            let v = totalViews
            var resultID = 5 // 默认为气质5
            
            // 规则判定
            if p < 3 && s < 3 && v < 3 {
                resultID = 1
            } else if p >= (s + v) * 3 {
                resultID = 2
            } else if s >= (p + v) * 3 {
                resultID = 3
            } else if p > 10 && s > 10 && v > 10 {
                resultID = 4
            }
            
            // 保存解锁记录
            saveUnlocked(resultID)
            // 重置计数，下一次就是新循环的“第一次”
            resetStats()
            
            return resultID
        }
        
        private func saveUnlocked(_ id: Int) {
            var idSet = Set(unlockedIDs.split(separator: ",").map { String($0) })
            idSet.insert("\(id)")
            unlockedIDs = idSet.joined(separator: ",")
        }
        
        private func resetStats() {
            totalPhotos = 0
            totalScans = 0
            totalViews = 0
            journeyCount = 0
        }

    // 保存本次旅程到成就
    func saveCurrentJourney(location: String, trainThumbnail: UIImage?, storyText: String, paragraphs: [StoryParagraph]) {
        let photosData = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let trainData = trainThumbnail?.jpegData(compressionQuality: 0.8)
        let modelNames = scannedModels.map { $0.name }

        let achievement = JourneyAchievement(
            storyText: "",        // 后续生成 AI 故事再更新
            paragraphs: paragraphs,
            photosData: photosData,
            modelNames: modelNames,
            location: location,
            trainThumbnailData: trainData
        )

        achievements.append(achievement)
        saveAchievementsToDisk()
    }

    // ---------------------------
    // 持久化
    // ---------------------------
    func saveAchievementsToDisk() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(achievements)
            UserDefaults.standard.set(data, forKey: "journeyAchievements")
        } catch {
            print("保存成就失败: \(error)")
        }
    }

    func loadAchievementsFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "journeyAchievements") {
            let decoder = JSONDecoder()
            if let saved = try? decoder.decode([JourneyAchievement].self, from: data) {
                achievements = saved
            }
        }
    }

    // 清空本次旅程记录
    func clear() {
        actions.removeAll()
        photos.removeAll()
        scannedModels.removeAll()
    }
}
