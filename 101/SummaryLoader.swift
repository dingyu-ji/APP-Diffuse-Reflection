//
//  SummaryLoader.swift
//  101
//
//  Created by 刘明 on 05/03/2026.
//

import Foundation
import UIKit
import RealityKit

extension UIImage {
    func withRoundedCorners(radius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}


@MainActor

class SummaryLoader: ObservableObject {
    
    var journeyRecorder: JourneyRecorder?
    
    @Published var progress: CGFloat = 1.0   // 1 → 0
    @Published var finished = false
    
    @Published var paragraphs: [StoryParagraph] = []
    
    
    var storyText: String = ""
    var photos: [UIImage] = []
    var models: [ScannedModel] = []
    
    func load(journeyRecorder: JourneyRecorder) async {
        self.journeyRecorder = journeyRecorder
        
        // 0% → 30%
        photos = journeyRecorder.photos
        await smoothProgress(from: 1.0, to: 0.7, duration: 0.3)
        
        // 30% → 60%
        models = journeyRecorder.scannedModels
        await smoothProgress(from: 0.7, to: 0.4, duration: 0.3)
        
        // 60% → 100% (AI 最慢)
        let logText = journeyRecorder.actions.joined(separator: ",")
        let aiStory = await AIManager.shared.generateStory(from: logText)
        storyText = aiStory
        paragraphs = StoryProcessor.process(text: storyText)
        
        
        await smoothProgress(from: 0.4, to: 0.0, duration: 0.5)
        
        let rawImage = UIImage(named: "chetou")
        let trainThumbnail = rawImage?.withRoundedCorners(radius: 100)
        
        journeyRecorder.saveCurrentJourney(
            location: "北京中轴线",
            trainThumbnail: trainThumbnail,
            storyText: storyText,
            paragraphs: paragraphs
        )
        
        // 更新最后一条成就的故事
        if let lastIndex = journeyRecorder.achievements.indices.last {
            journeyRecorder.achievements[lastIndex].storyText = aiStory
            journeyRecorder.saveAchievementsToDisk()
            
        }
        
        finished = true
        
    }
    
//    func processStoryIntoParagraphs(){
//        
//        paragraphs = StoryProcessor.process(text: storyText)
//    }
    
    
    func smoothProgress(from start: CGFloat, to end: CGFloat, duration: TimeInterval) async {
        let steps = 30
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let value = start + t * (end - start)
            await MainActor.run { self.progress = value }
            try? await Task.sleep(nanoseconds: UInt64(duration / Double(steps) * 1_000_000_000))
        }
    }
    
    func loadCompleteModel(for targetImageName: String) -> UIImage? {
        guard let modelFileName = fullModelMapping[targetImageName] else { return nil }
//        do {
//            return try ModelEntity.loadModel(named: "\(modelFileName).usdz")
//        } catch {
//            print("加载完整模型失败:", error)
//            return nil
//        }
        let image = UIImage(named: modelFileName)
                
                if image == nil {
                    print("加载图片失败: \(modelFileName)")
                }
                
                return image
    }
    
}
