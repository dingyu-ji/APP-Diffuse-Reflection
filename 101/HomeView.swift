//
//  HomeView.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//

import SwiftUI
import RealityKit

struct HomeView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var bleManager: BLEManager

    @StateObject var angleTracker = AngleTracker()
    @StateObject var journeyRecorder = JourneyRecorder()

    @State private var timer3s: Timer? = nil
    @State private var showScenicSpot = false
    @State private var selectedSpot: ScenicSpot? = nil
    @State private var lastSig: String = "none"
    @State private var canExit = false
    @State private var visitedSpots: Set<String> = []

    // 背景淡入
    @State private var showBackground = false

    // ------------------------
    // 动画状态
    // ------------------------
    @State private var dialExpanded = false
    @State private var pointerVisible = true
    @State private var dialColorState = Color(hex: "#fff3b0")
    @State private var animationTriggered = false
    @State private var fillScreen = false  // 新增：控制圆盘填满屏幕

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景图
                Image("homeBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(showBackground ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.2), value: showBackground)

                // 仪表盘
                VStack {
                    Spacer()
                    ZStack {
                        // 圆盘：原始位置 + 填满屏幕动画
                        Circle()
                            .fill(fillScreen ? dialColorState : dialColor(for: angleTracker.currentAngle))
                            .frame(width: dialExpanded ? 300 : 300,
                                   height: dialExpanded ? 300 : 300)
                            .scaleEffect(fillScreen ? UIScreen.main.bounds.height*2 / 300 : 1.0) // 放大至屏幕
                            .offset(x: 5, y: 30)
                            .animation(.easeInOut(duration: 1.5), value: fillScreen)

                        // 指针和中央数字
                        if pointerVisible {
                            // 刻度
                            ForEach(0..<360) { i in
                                let isLong = i % 10 == 0
                                Rectangle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 2, height: isLong ? 12 : 6)
                                    .offset(y: -125)
                                    .rotationEffect(.degrees(Double(i)))
                                    .offset(x: 5, y: 30)
                            }

                            // 指针
                            let pointerAngle = (angleTracker.currentAngle / 90.0) * 360.0
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 3, height: 120)
                                .offset(y: -60)
                                .rotationEffect(.degrees(pointerAngle))
                                .animation(.easeInOut(duration: 0.2), value: angleTracker.currentAngle)
                                .offset(x: 5, y: 30)

                            // 中央数字
                            Text("\(Int(angleTracker.currentAngle))°")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: 5, y: 30)
                        }
                    }
                    Spacer()
                }

                // -------------------------
                // 原有按钮保持不变
                // -------------------------
                VStack {
                    Spacer()
//                    Button("模拟旅程结束") {
//                        endJourney()
//                    }
//                    .padding()
//                    
//                    Button("模拟") {
//                        triggerScenicSpot(with: "spot1")
//                    }
//                    .padding()
                }
                .padding()
            }
            .navigationDestination(item: $selectedSpot) { spot in
                ScenicSpotView(spot: spot) {
                    resumeTracking()
                }
            }
            .onChange(of: angleTracker.currentAngle) { oldValue, newValue in
                handleRealtimeAngle(newValue)
            }
            .onAppear {
                angleTracker.startTracking()

                timer3s = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    angleTracker.recordCurrentAngle()
                }

                bleManager.onReceive = { spotID in
                    DispatchQueue.main.async {
                        handleBLE(spotID)
                    }
                }

                withAnimation(.easeInOut(duration: 1.2)) {
                    showBackground = true
                }
            }
            .onDisappear {
                angleTracker.stopTracking()
                timer3s?.invalidate()
            }
        }
    }

    private func dialColor(for angle: Double) -> Color {
        let base = Color(hex: "#eae8e0")
        let maxColor = Color(hex: "#fff3b0")
        let t = min(max(angle / 90.0, 0.0), 1.0)
        let baseR = base.red
        let baseG = base.green
        let baseB = base.blue
        let maxR = maxColor.red
        let maxG = maxColor.green
        let maxB = maxColor.blue
        let r = baseR + (maxR - baseR) * t
        let g = baseG + (maxG - baseG) * t
        let b = baseB + (maxB - baseB) * t
        return Color(red: r, green: g, blue: b)
    }

    // -------------------------
    // 仪表盘颜色 + 扩展动画 + 填满屏幕渐变
    // -------------------------
    private func handleRealtimeAngle(_ angle: Double) {
        
        guard appState.currentScreen == .home else {return}
        
        let inRange = angle >= 60 && angle <= 95

        guard inRange && !animationTriggered else { return }
        animationTriggered = true
        pointerVisible = false

        // 1️⃣ 扩大到填满屏幕
        withAnimation(.easeInOut(duration: 1.5)) {
            fillScreen = true
        }

        // 2️⃣ 圆盘填满后颜色渐变
        withAnimation(.easeInOut(duration: 1.5).delay(0.8)) {
            dialColorState = Color(hex: "#eae8df")
        }

        // 3️⃣ 延迟切换页面，动画完成后恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            appState.currentScreen = .actionSelection

            // 重置状态，下次返回 home 再触发
            fillScreen = false
            pointerVisible = true
            animationTriggered = false
        }
    }

    // -------------------------
    // 原有函数保持不变
    // -------------------------
    func endJourney() {
        let story = generateStory(from: journeyRecorder.actions)
        appState.currentStory = story
        appState.currentPhotos = journeyRecorder.photos
        appState.currentModels = journeyRecorder.scannedModels
        appState.currentScreen = .loadingConnect
    }

    func generateStory(from actions: [String]) -> String {
        actions.joined(separator: "-.")
    }

    private func handleBLE(_ spotID: String) {
        guard appState.currentScreen == .home else { return }
        
        let requiredSpots: Set<String> = ["spot1", "spot2", "spot3", "spot4", "spot5"]
        
        // --- 逻辑 A：判断是否是“集齐后的重复信号” ---
        // 如果已经集齐了全部 5 个，且这次收到的信号是这 5 个中的任意一个
        let alreadyHasAll = requiredSpots.isSubset(of: visitedSpots) && requiredSpots.contains(spotID)
        
        if alreadyHasAll{
            endJourney()
            angleTracker.clearHistory()
            return // 结束旅程，不再往下走
        }else {
            // 情况 B：还没集齐
            // 将当前收到的信号放入已访问集合
            visitedSpots.insert(spotID)
        }

        // --- 逻辑 B：正常的景点触发逻辑（45度姿态） ---
        guard !angleTracker.angleHistory.isEmpty else { return }
        let count35_55 = angleTracker.angleHistory.filter { $0 >= 35 && $0 <= 55 }.count
        let total = angleTracker.angleHistory.count
        let ratio = Double(count35_55) / Double(total)

        if ratio >= 0.5 {
            // 只有在满足 45 度姿态时，才记录该景点并弹出页面
            visitedSpots.insert(spotID)
            
            // 弹出对应的景点介绍页
            triggerScenicSpot(with: spotID)
            angleTracker.clearHistory()
        }
    }

    private func triggerScenicSpot(with id: String) {
        guard let spot = ScenicSpotRepository.spot(with: id) else { return }
        pauseTracking()
        selectedSpot = spot
        angleTracker.clearHistory()
    }

    private func pauseTracking() {
        timer3s?.invalidate()
    }

    private func resumeTracking() {
        selectedSpot = nil
        showScenicSpot = false
        timer3s = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            angleTracker.recordCurrentAngle()
        }
    }
}
