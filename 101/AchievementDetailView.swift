
//
//  AchievementDetailView.swift
//  101
//
//  Created by 刘明 on 02/03/2026.
//

import SwiftUI
import RealityKit

struct AchievementDetailView: View {
    let achievement: JourneyAchievement

    @Environment(\.presentationMode) var presentationMode
    // 注入蓝牙管理，用于打印
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var summaryLoader: SummaryLoader
    
    @State private var scrollOffset: CGFloat = 0
    @State private var showPrintDialog = false // 打印弹窗状态控制

    // 消失线距离屏幕顶部
    private let disappearLine: CGFloat = 70
    private let containerMaxWidth: CGFloat = 245
    private let containerOffsetX: CGFloat = 56

    var body: some View {
            // 【完全复刻 SummaryView 的顶级 ZStack 结构】
            ZStack {
                
                // --------------------------------------------------
                // 第一层：背景与滚动内容 (逻辑严丝合缝)
                // --------------------------------------------------
                ZStack(alignment: .bottom) {
                    // 背景
                    Image("film_background")
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.2)
                        .offset(x: -10, y: 70)
                        .ignoresSafeArea()

                    GeometryReader { geo in
                        ScrollView {
                            VStack(spacing: 20) {
                                
                                // 旅程故事
                                HStack {
                                    Spacer().frame(width: 20)
                                    JourneySectionContainer(title: "旅程故事") {
                                        ForEach(achievement.paragraphs) { paragraph in
                                            StoryParaView(paragraph: paragraph) { }
                                                .disabled(true) // 详情页不可点选单词
                                        }
                                    }
                                    .frame(maxWidth: 245)
                                    .offset(x: 56, y: 0)
                                    Spacer()
                                }

                                // 拍摄照片
                                HStack {
                                    Spacer().frame(width: 20)
                                    JourneySectionContainer(title: "拍摄照片") {
                                        ScrollView(.horizontal) {
                                            HStack(spacing: 10) {
                                                ForEach(achievement.photosData, id: \.self) { data in
                                                    if let image = UIImage(data: data) {
                                                        Image(uiImage: image)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 120, height: 120)
                                                            .cornerRadius(8)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: 245)
                                    .offset(x: 56, y: 0)
                                    Spacer()
                                }

                                // 浏览模型
                                HStack {
                                    Spacer().frame(width: 20)
                                    JourneySectionContainer(title: "浏览模型") {
                                        ScrollView(.horizontal) {
                                            HStack(spacing: 20) {
                                                ForEach(achievement.modelNames, id: \.self) { targetName in
                                                    if let uiImage = loadCompleteModel(for: targetName) {
                                                        Color.clear
                                                            .frame(width: 250, height: 250)
                                                            .overlay(
                                                                Image(uiImage: uiImage)
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fit)
                                                                    .padding(30)
                                                            )
                                                            .background(Color.gray.opacity(0.1))
                                                            .cornerRadius(8)
                                                            .shadow(radius: 3)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: 245)
                                    .offset(x: 56, y: 0)
                                    Spacer()
                                }

                                Spacer().frame(height: 100)
                            }
                            .padding(.vertical, 20)
                            .padding(.top, 100)
                            .background(
                                GeometryReader { innerGeo in
                                    Color.clear
                                        .preference(key: ScrollOffsetKey.self, value: innerGeo.frame(in: .global).minY)
                                }
                            )
                        }
                        .onPreferenceChange(ScrollOffsetKey.self) { offset in
                            scrollOffset = offset
                        }
                        .mask(
                            VStack {
                                Rectangle()
                                    .frame(height: max(0, geo.size.height - disappearLine))
                                    .offset(y: disappearLine)
                                Spacer()
                            }
                        )
                    }
                }

                // --------------------------------------------------
                // 第二层：控制按钮层 (返回左上，打印右下)
                // --------------------------------------------------
                VStack {
                    // 返回按钮死磕左上角
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image("backButton")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        .padding(.top, 60)
                        .padding(.leading, 20)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // 打印按钮死磕右下角
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) { showPrintDialog = true }
                        }) {
                            Image("print_btn") // 确保 Assets 里有这个图，或者改回 backButton
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                        }
                        .padding(30)
                    }
                }

                // --------------------------------------------------
                // 第三层：打印确认弹窗 (完全照搬 SummaryView 弹窗布局)
                // --------------------------------------------------
                if showPrintDialog {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        
                        ZStack {
                            // 1. 手绘透明底背景
                            Image("print_bg")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 320)
                            
                            VStack(spacing: 30) {
                                // 2. 文字
                                Text("打印吗？")
                                    .appFont(AppFont.title())
                                    .foregroundColor(.black)
                                    .padding(.top, 20)
                                
                                // 3. 两个按钮
                                HStack(spacing: 40) {
                                    Button(action: {
                                        printJourneyContent()
                                        showPrintDialog = false
                                    }) {
                                        Text("是")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .frame(width: 80, height: 40)
                                            .border(Color.black, width: 2)
                                    }
                                    
                                    Button(action: { showPrintDialog = false }) {
                                        Text("否")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 80, height: 40)
                                            .background(Color.black)
                                    }
                                }
                            }
                            
                            // 4. 右上角关闭
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: { showPrintDialog = false }) {
                                        Image("deleteBtn")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                    .padding(10)
                                }
                                Spacer()
                            }
                            .frame(width: 320, height: 220)
                        }
                    }
                    .zIndex(200) // 确保在最顶层
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }

    // ---------------------------
    // 打印逻辑函数 (完整保留)
    // ---------------------------
    func printJourneyContent() {
        guard let p = bleManager.printerPeripheral,
              let char = bleManager.printerCharacteristic else {
            print("打印机连接失效")
            return
        }

        let command = EscCommand()
        command.addInitializePrinter()
        command.addSelectKanjiMode()
        
//        // 1. 处理图片
//            if let rawImage = UIImage(named: "money") {
//                
//                command.addOriginrastBitImage(rawImage)
//            }
//            
//            command.addPrintAndLineFeed() // 换行
//            command.addText("图片打印测试\n")
//            command.addPrintAndFeedLines(4) // 留白，防止撕纸时撕到内容
//
//            // 2. 执行发送 (之前你注释掉了这段，所以没反应)
//            if let data = command.getCommand() {
//                print("--- 总字节数: \(data.count) ---")
//                
//                let chunkSize = 20 // 坚持用 20，最稳
//                var offset = 0
//                
//                // 开启异步全局队列发送，防止 Thread.sleep 阻塞主线程 UI
//                DispatchQueue.global(qos: .userInitiated).async {
//                    while offset < data.count {
//                        let length = min(data.count - offset, chunkSize)
//                        let subdata = data.subdata(in: offset..<(offset + length))
//                        
//                        // 核心：发送数据到打印机
//                        p.writeValue(subdata, for: char, type: .withoutResponse)
//                        
//                        offset += length
//                        
//                        // 重点：图片数据大，稍微给打印机一点喘息时间
//                        // 如果图片还打不出来，把 0.01 改成 0.03
//                        Thread.sleep(forTimeInterval: 0.01)
//                    }
//                    print("--- 数据发送完毕 ---")
//                }
//            }
        
        // 标题
        command.addSetJustification(1)
        command.addSetCharcterSize(0x11)
        command.addText("旅程故事\n\n")
        
        // 补充地点
        command.addSetCharcterSize(0x00)
        command.addText("地点：\(achievement.location)\n\n")
        
        // 内容
        command.addSetJustification(0)
        for paragraph in achievement.paragraphs {
            command.addText(paragraph.text)
            command.addPrintAndLineFeed()
            command.addPrintAndLineFeed()
        }
        
        command.addPrintAndFeedLines(5)
        
        if let data = command.getCommand() {
            let chunkSize = 20
            var offset = 0
            while offset < data.count {
                let length = min(data.count - offset, chunkSize)
                let subdata = data.subdata(in: offset..<(offset + length))
                p.writeValue(subdata, for: char, type: .withoutResponse)
                offset += length
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
    }

    func loadCompleteModel(for targetImageName: String) -> UIImage? {
        guard let modelFileName = fullModelMapping[targetImageName] else { return nil }
        let image = UIImage(named: modelFileName)
        if image == nil { print("加载图片失败: \(modelFileName)") }
        return image
    }
}

