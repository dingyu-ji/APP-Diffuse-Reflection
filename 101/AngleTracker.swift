//
//  AngleTracker.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//

import SwiftUI
import Combine
import CoreMotion

class AngleTracker: ObservableObject {
    
    @Published var currentAngle: Double = 0.0
    
    // 历史角度数组，公开可修改
    @Published var angleHistory: [Double] = []
    
    private var motionManager: CMMotionManager?
    private var timer: Timer?
    
    init() {
        motionManager = CMMotionManager()
    }
    
    func startTracking() {
        guard let manager = motionManager else { return }
        
        // 使用 deviceMotion 更新 currentAngle
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.1
            manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }
                // 这里用 roll 作为示例角度
                let pitchDegrees = motion.attitude.pitch * 180 / .pi
                self.currentAngle = abs(pitchDegrees)
            }
        }
    }
    
    func stopTracking() {
        motionManager?.stopDeviceMotionUpdates()
        timer?.invalidate()
    }
    
    // 每3秒记录一次 currentAngle
    func recordCurrentAngle() {
        angleHistory.append(currentAngle)
    }
    
    // 清空历史角度
    func clearHistory() {
        angleHistory.removeAll()
    }
}
