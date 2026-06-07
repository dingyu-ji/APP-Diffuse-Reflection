import SwiftUI
import RealityKit

struct SummaryView: View {
    @EnvironmentObject var journeyRecorder: JourneyRecorder
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var summaryLoader: SummaryLoader
    @EnvironmentObject var galleryStore: GalleryStore
    @EnvironmentObject var bleManager: BLEManager

    @State private var selectedParagraph: Int? = nil
    @State private var showingWordSheet = false
    @State private var currentParagraphIndex: Int = 0
    @State private var containerStartY: CGFloat = 0
    
    // ✨ 旅程气质状态
    @State private var showTemperamentCard = false
    @State private var revealedID: Int = 1
    @State private var cardScale: CGFloat = 0.1
    @State private var cardRotation: Double = -180
    @State private var showCloseButton = false

    // 🖨️ 新增：打印弹窗状态
    @State private var showPrintDialog = false

    private let disappearLine: CGFloat = 70

    var body: some View {
        // 使用顶级 ZStack 包裹所有层
        ZStack {
            // --------------------------------------------------
            // 原有 UI 内容 (完全保留原有逻辑，不许动)
            // --------------------------------------------------
            ZStack(alignment: .bottom) {
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
                                    ForEach(summaryLoader.paragraphs.indices, id: \.self) { i in
                                        let paragraph = summaryLoader.paragraphs[i]
                                        StoryParaView(paragraph: paragraph) {
                                            showWordSelection(paragraphIndex: i)
                                        }
                                    }
                                }
                                .frame(maxWidth: 245)
                                .offset(x: 56, y:0)
                                Spacer()
                            }

                            // 拍摄照片
                            HStack {
                                Spacer().frame(width: 20)
                                JourneySectionContainer(title: "拍摄照片") {
                                    ScrollView(.horizontal) {
                                        HStack(spacing: 10) {
                                            ForEach(journeyRecorder.photos, id: \.self) { photo in
                                                Image(uiImage: photo)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 120, height: 120)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: 245)
                                .offset(x: 56, y:0)
                                Spacer()
                            }

                            // 浏览模型
                            HStack {
                                Spacer().frame(width: 20)
                                JourneySectionContainer(title: "浏览模型") {
                                    ScrollView(.horizontal) {
                                        HStack(spacing: 20) {
                                            ForEach(journeyRecorder.scannedModels, id: \.id) { scanned in
                                            if let uiImage = summaryLoader.loadCompleteModel(for: scanned.name) {
                                                Color.clear // 使用透明底作为占位
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
                                                } else {
                                                    Text("模型加载失败")
                                                        .frame(width: 250, height: 250)
                                                        .background(Color.gray.opacity(0.2))
                                                        .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: 245)
                                .offset(x: 56, y:0)
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

                Button(action: {
                    appState.currentScreen = .personal
                }) {
                    Image("next")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .position(x: 320, y: 60)
            }

            // --------------------------------------------------
            // ✨ 旅程气质弹窗层 (保留原有逻辑)
            // --------------------------------------------------
            if showTemperamentCard {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                    Image("Card_气质\(revealedID)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 380)
                        .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
                        .scaleEffect(cardScale)
                        .onAppear {
                            withAnimation(.interpolatingSpring(stiffness: 45, damping: 7)) {
                                cardRotation = 0
                                cardScale = 1.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showCloseButton = true }
                            }
                        }
                        .overlay(
                            ZStack {
                                if showCloseButton {
                                    Button {
                                        withAnimation {
                                            showTemperamentCard = false
                                            showCloseButton = false
                                        }
                                    } label: {
                                        Image("deleteBtn")
                                            .resizable()
                                            .frame(width: 45, height: 45)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                    .offset(x: -25, y: 25)
                                }
                            },
                            alignment: .topTrailing
                        )
                }
                .zIndex(100)
            }

            // --------------------------------------------------
            // 🖨️ 新增：右下角手绘打印按钮 (放在所有内容之上)
            // --------------------------------------------------
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) { showPrintDialog = true }
                    }) {
                        Image("print_btn") // 你的手绘打印机按钮图print_btn
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                    }
                    .padding(30)
                }
            }

            // --------------------------------------------------
            // 🖨️ 新增：打印确认弹窗 (代码生成文字与按钮形状)
            // --------------------------------------------------
            if showPrintDialog {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    // 弹窗容器
                    ZStack {
                        // 1. 手绘透明底背景
                        Image("print_bg")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320)
                        
                        VStack(spacing: 30) {
                            // 2. 文字“打印吗？”
                            Text("打印吗？")
                                .appFont(AppFont.title())
                                .foregroundColor(.black)
                                .padding(.top, 20)
                            
                            // 3. 两个按钮
                            HStack(spacing: 40) {
                                // “是” 按钮：黑色长方框（空心）
                                Button(action: {
                                    showPrintDialog = false
                                }) {
                                    Text("否")
                                        .appFont(AppFont.title())
                                        .foregroundColor(.black)
                                        .frame(width: 80, height: 40)
                                        .border(Color.black, width: 2) // 黑色长方框
                                }
                                
                                // “否” 按钮：黑色长方形（实心）
                                Button(action: {
                                    printJourneyContent()
                                    showPrintDialog = false
                                }) {
                                    Text("是")
                                        .appFont(AppFont.title())
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 40)
                                        .background(Color.black) // 黑色实心长方形
                                }
                            }
                        }
                        
                        // 4. 右上角关闭按钮 (手绘图)
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { showPrintDialog = false }) {
                                    Image("deleteBtn") // 复用你已有的删除按钮图
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }
                                .padding(10)
                            }
                            Spacer()
                        }
                        .frame(width: 320, height: 220) // 约束关闭按钮范围
                    }
                }
                .zIndex(200) // 确保在最顶层
            }
        }
        .onAppear {
            if let resultID = journeyRecorder.judgeTemperament() {
                revealedID = resultID
                cardRotation = -90
                cardScale = 0.1
                showCloseButton = false
                showTemperamentCard = true
            }
        }
        .sheet(isPresented: $showingWordSheet) {
            WordSelectionSheet(
                paragraph: summaryLoader.paragraphs[currentParagraphIndex]
            ) { selectedWords in
                let bestImage = ImageMatcher.match(selectedWords: selectedWords, gallery: galleryStore.images)
                summaryLoader.paragraphs[currentParagraphIndex].matchedImage = bestImage
                if let lastIndex = journeyRecorder.achievements.indices.last {
                    journeyRecorder.achievements[lastIndex].paragraphs[currentParagraphIndex].matchedImage = bestImage
                    journeyRecorder.saveAchievementsToDisk()
                }
                showingWordSheet = false
            }
        }
    }

    @State private var scrollOffset: CGFloat = 0

    func showWordSelection(paragraphIndex: Int) {
        currentParagraphIndex = paragraphIndex
        showingWordSheet = true
    }

    // 🖨️ 打印核心函数
//    func printJourneyContent() {
//        // 1. 获取所有旅程故事文字
//        let content = summaryLoader.paragraphs.map { $0.text }.joined(separator: "\n\n")
//        
//        // 2. 准备打印控制器 (来自 UIKit)
//        let printController = UIPrintInteractionController.shared
//        
//        // 3. 配置打印信息
//        let printInfo = UIPrintInfo(dictionary: nil)
//        printInfo.jobName = "Journey Story"
//        printInfo.outputType = .general
//        printController.printInfo = printInfo
//        
//        // 4. 配置文字格式化器 (来自 UIKit)
//        let formatter = UISimpleTextPrintFormatter(text: content)
//        formatter.perPageContentInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
//        printController.printFormatter = formatter
//        
//        // 5. 弹出系统打印界面
//        printController.present(animated: true, completionHandler: nil)
//    }
    
    func printJourneyContent() {
        // 1. 检查蓝牙连接状态
        guard let peripheral = bleManager.printerPeripheral,
              let characteristic = bleManager.printerCharacteristic else {
            print("❌ 错误：打印机未连接")
            return
        }

        // 2. 初始化 EscCommand (小票模式)
        let command = EscCommand()
        
        command.addNSData(toCommand: Data([0x1B, 0x40]))
        // 打印机初始化 (对应 0x1b, 0x40)
        //command.addInitializePrinter()
        // 开启汉字模式
//        command.addSelectKanjiMode()
//        
        // 3. 打印标题
        // 设置居中 (0:左, 1:中, 2:右)
        command.addSetJustification(1)
        // 设置倍高倍宽 (0x11 通常代表宽高各放大一倍)
        command.addSetCharcterSize(0x11)
        command.addText("旅程故事\n")
        
        // 4. 打印正文
        // 恢复左对齐
        command.addSetJustification(0)
        // 恢复正常大小
        command.addSetCharcterSize(0x00)
        // 换行留点空隙
        command.addPrintAndLineFeed()
        
        // 遍历段落
        for paragraph in summaryLoader.paragraphs {
            let text = paragraph.text
            
            // 在 ESC 模式下，直接输入文字即可
            // 打印机会根据纸张宽度 (PT-260 通常是 384 点/行) 自动换行
            command.addText(text)
            
            // 每个段落后加两个换行，让排版更美观
            command.addPrintAndLineFeed()
            command.addPrintAndLineFeed()
        }
        
        // 5. 结尾走纸
        // 打印完后多走几行，方便撕纸
        command.addPrintAndFeedLines(5)
        
        // 6. 获取数据并【分段】发送
                if let data = command.getCommand() {
                    print("数据总长度：\(data.count) 字节")
                    
                    let chunkSize = 20 // 每次发送 20 字节，这最稳妥
                    var offset = 0
                    
                    while offset < data.count {
                        let length = min(data.count - offset, chunkSize)
                        let subdata = data.subdata(in: offset..<(offset + length))
                        
                        // 真正执行发送
                        peripheral.writeValue(subdata,
                                              for: characteristic,
                                              type: .withoutResponse)
                        
                        offset += length
                        // 给硬件一点点反应时间（0.01秒）
                        Thread.sleep(forTimeInterval: 0.01)
                    }
                    
                    print("✅ 完整故事已分段发送完毕")
                }
        
        
//        // 简单的测试文本
//            command.addSetJustification(1) // 居中
//            command.addText("TEST PRINT\n")
//            command.addText("测试打印\n")
//            command.addPrintAndFeedLines(5)
            
            if let data = command.getCommand() {
                print("发送字节数: \(data.count)")
                // 这里打一个断点，确认 data 里面前两个字节是不是 1b 40
                peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
