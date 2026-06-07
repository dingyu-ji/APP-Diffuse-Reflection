//
//  ScanView.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//

import SwiftUI
import RealityKit
import ARKit
import Vision
import Combine

struct InvertedCircleShapeScan: Shape {
    var center: CGPoint
    var radius: CGFloat
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        let hole = Path { p in
            p.addArc(center: center, radius: max(0, radius), startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        }
        path.addPath(hole)
        return path
    }
}

extension Notification.Name{
    static let partSelected = Notification.Name("partSelected")
    static let partInfoClosed = Notification.Name("partInfoClosed")
    static let showPartInfo = Notification.Name("showPartInfo")
    static let forceCleanupAR = Notification.Name("forceCleanupAR")
}

// 辅助扩展：在容器内寻找第一个可用的模型
extension Entity {
    func findFirstModelEntity() -> ModelEntity? {
        if let model = self as? ModelEntity { return model }
        for child in children {
            if let found = child.findFirstModelEntity() { return found }
        }
        return nil
    }
}

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var journeyRecorder: JourneyRecorder

    @State private var showPartInfo = false
    @State private var selectedPartName: String = ""
    @State private var maskRadius: CGFloat = 0
    @State private var isAnimationFinished = false
    @State private var joystickVector: CGPoint = .zero
    @State private var showJoystick: Bool = false
    @State private var arSessionID = UUID()  // 新增：控制ARView重建
    @State private var isRebuilding = false  // 新增：重建期间显示遮罩

    var body: some View {
        ZStack {
            // 关键：.id(arSessionID) 变化时SwiftUI完全销毁旧ARContainer创建新的
            ARContainer(joystickVector: $joystickVector, isTargetFound: $showJoystick, sessionID: arSessionID)
                .id(arSessionID)
                .edgesIgnoringSafeArea(.all)

            if isAnimationFinished {
                Button(action: {
                    NotificationCenter.default.post(name: .forceCleanupAR, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        appState.currentScreen = .actionSelection
                    }
                }) {
                    Image("backButton")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding(8)
                }
                .position(x: 60, y: 40)

                VStack {
                    Spacer()
                    HStack {
                        if showJoystick {
                            JoystickView(vector: $joystickVector)
                                .frame(width: 150, height: 150)
                                .padding(.leading, 30)
                                .padding(.bottom, 50)
                                .onChange(of: joystickVector) { newValue in }
                            Spacer()
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                }

                VStack {
                    Spacer()
                    if showPartInfo {
                        PartInfoView(isPresented: $showPartInfo,
                                     partName: selectedPartName)
                        .frame(height: UIScreen.main.bounds.height * 0.45)
                        .transition(.move(edge: .bottom))
                    }
                }
            }

            // 进入动画遮罩
            if !isAnimationFinished {
                Image("transitionPhoto")
                    .resizable()
                    .frame(width: UIScreen.main.bounds.width,
                           height: UIScreen.main.bounds.height)
                    .scaledToFill()
                    .mask(
                        InvertedCircleShapeScan(
                            center: CGPoint(x: UIScreen.main.bounds.midX,
                                           y: UIScreen.main.bounds.midY),
                            radius: maskRadius
                        )
                        .ignoresSafeArea()
                    )
            }

            // 新增：ARView重建期间的黑屏遮罩，防止用户看到重建过程
            if isRebuilding {
                ARRebuildingOverlay()
                        .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showPartInfo)
        .onReceive(NotificationCenter.default.publisher(for: .showPartInfo)) { notification in
            if let userInfo = notification.userInfo,
               let partName = userInfo["partName"] as? String {
                selectedPartName = partName
                showPartInfo = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .partInfoClosed)) { _ in
            self.showPartInfo = false
            self.selectedPartName = ""
        }
        // 新增：监听需要重建ARView的通知
        .onReceive(NotificationCenter.default.publisher(for: .forceCleanupAR)) { _ in
            // 只在扫描页面内部的模型切换时重建
            // 如果是返回按钮触发的，appState会切换页面，不需要重建
            guard appState.currentScreen == .scan else { return }
            
            // 1. 显示黑屏遮罩
            isRebuilding = true
            showPartInfo = false
            selectedPartName = ""
            showJoystick = false
            
            // 2. 延迟一帧让dismantleUIView有时间执行prepareForDeinit
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 3. 换新UUID，触发ARView完全销毁重建
                arSessionID = UUID()
                
                // 4. 再等一点让新ARView初始化完成，再撤掉遮罩
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    isRebuilding = false
                }
            }
        }
        .onAppear {
            maskRadius = 0
            isAnimationFinished = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let screen = UIScreen.main.bounds
                let finalRadius = sqrt(pow(screen.width, 2) + pow(screen.height, 2))

                withAnimation(.easeIn(duration: 0.7)) {
                    maskRadius = finalRadius
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    isAnimationFinished = true
                }
            }
        }
    }
}

// ============================================
// ARContainer
// ============================================
struct ARContainer: UIViewRepresentable {
    @EnvironmentObject var journeyRecorder: JourneyRecorder
    @Binding var joystickVector: CGPoint
    @Binding var isTargetFound: Bool
    let sessionID: UUID  // 新增：用于触发重建

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic

        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            config.detectionImages = referenceImages
            config.maximumNumberOfTrackedImages = 1
        }

        arView.session.delegate = context.coordinator
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        context.coordinator.arView = arView
        context.coordinator.journeyRecorder = journeyRecorder

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        arView.addGestureRecognizer(longPress)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.setupHandPoseDetection(arView: arView)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.onTargetImageFound = { found in
            self.isTargetFound = found
        }
        return coordinator
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.joystickVector = joystickVector
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.prepareForDeinit()
    }
}

// ============================================
// Coordinator
// ============================================
class Coordinator: NSObject, ARSessionDelegate {

    var arView: ARView?
    var journeyRecorder: JourneyRecorder?
    var onTargetImageFound: ((Bool) -> Void)?
    
    // 在 Coordinator 类中添加
    struct CharacterConfig {
        let scale: SIMD3<Float>
        let parts: [String]      // 分部件加载
        let lightPart: String    // 带灯光的部件名
        let moveSpeed: Float = 0.02
    }
    
        // 人物模型专用注册表
        let characterRegistry: [String: CharacterConfig] = [
            "宫灯": CharacterConfig(
                scale: [0.2, 0.2, 0.2],
                parts: ["dl1","dl2"], // 替换为你实际的 .usdz 文件名
                lightPart: "dl2"
            )
        ]

        // 人物逻辑状态
        private var characterRoot: Entity?
        private var isCharacterMode = false
        private var characterMoveSubscription: Cancellable?
        var joystickVector: CGPoint = .zero // 用于 SwiftUI 监听
        private var isCharacterMoving: Bool = false

    private var highlightedPart: ModelEntity?
    private var highlightedOutline: ModelEntity?
    
    private var isModelLoading = false

    // ===== 亮灯管理：点光源字典 =====
    private var activeLights: [Entity: PointLight] = [:]
    private var lightTimers: [Entity: Timer] = [:]

    struct ModelConfig {
        let scale: SIMD3<Float>
        let parts: [String]
        let explodeOffsets: [SIMD3<Float>]
        let lightParts: [String]?
    }
    
    

    let modelRegistry: [String: ModelConfig] = [
        "天坛": ModelConfig(
            scale: [0.002, 0.002, 0.002],
            parts: ["y1","y2","y3","y4","y5","y6","y7","y8"],
            explodeOffsets: [
                [0.09, 0, 0], [-0.09, 0, 0], [0.00, 0.09, 0.00],
                [0.00, -0.09, 0.00], [0.00, 0.00, 0.09], [0.00, 0.00, -0.09],
                [0.05, 0.05, 0.05],[0.00, -0.05, 0.05]
            ],
            lightParts: ["y3"]
        ),
        "天安门": ModelConfig(
            scale: [0.002, 0.002, 0.002],
            parts: ["t1","t2","t3","t4"],
            explodeOffsets: [
                [0.005, 0, 0], [0.00, 0.005, 0.00], [0.00, 0.00, 0.005], [0.005, 0.005, 0.005]
            ],
            lightParts: ["t1"]
        ),
        "故宫": ModelConfig(
            scale: [0.005, 0.005, 0.005],
            parts: ["g1","gl1","g2","gl2","g3","gl3","g4"],
            explodeOffsets: [
                [0.09, 0, 0], [0.09, 0, 0], [0.00, 0.09, 0.00], [0.00, 0.09, 0.00], [0.00, 0.00, 0.09], [0.00, 0.00, 0.09], [0.05, 0.05, 0.05]
            ],
            lightParts: ["gl1", "gl2", "gl3"]
        ),
        "景山公园": ModelConfig(
            scale: [0.09, 0.09, 0.09],
            parts: ["w1","w2","w3","w4","w5","w6"],
            explodeOffsets: [
                [0.09, 0, 0], [0.09, 0, 0], [0.00, 0.09, 0.00], [0.00, 0.09, 0.00], [0.00, 0.00, 0.09], [0.00, 0.00, 0.09]
            ],
            lightParts: ["w2"]
        ),
        
        "永定门": ModelConfig(
            scale: [0.0006, 0.0006, 0.0006],
            parts: ["d1","d2","d3","d4"],
            explodeOffsets: [
                [0.09, 0, 0], [0.00, 0.09, 0.00], [0.00, 0.00, 0.09], [0.05, 0.05, 0.05]
            ],
            lightParts: ["d1"]
        )
    ]

    private var currentParts: [ModelEntity] = []
    private var originalTransforms: [ModelEntity: Transform] = [:]
    private var isExploded = false
    private var rootEntity: ModelEntity?
    private var currentAnchor: AnchorEntity?

    struct AnimatedModelConfig {
        let scale: SIMD3<Float>
        let parts: [String]
        let loopAnimation: Bool
        let lightParts: [String]?
    }

    let animatedModelRegistry: [String: AnimatedModelConfig] = [
        "祥云": AnimatedModelConfig(
            scale: [0.01, 0.01, 0.01],
            parts: ["c1","c2","c3","c4","c5","c6","c7"],
            loopAnimation: true,
            lightParts: nil
        ),
        
        "铛铛车": AnimatedModelConfig(
            scale: [0.02, 0.02, 0.02],
            parts: ["dc1","dc2","dc3","dc4","dc5","dc6","dc7","dc8","dc9","dc10"],
            loopAnimation: true,
            lightParts: ["dc1","dc2","dc3","dc4","dc5","dc6","dc7","dc8"]
        )
    ]

    private var animatedParts: [ModelEntity] = []
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handPoseSequenceHandler = VNSequenceRequestHandler()
    private var lastHitEntities: Set<ModelEntity> = []

    // 【添加】：Timer 引用，方便销毁
    private var detectionTimer: Timer?
    
    @objc func triggerSystemCleanup() {
        print("🧹 正在触发安全内存回收...")
        
        // 1. 这种方法是官方允许的，通过发送内存压力通知，诱导系统清理各个框架的缓存
        // 虽然不如私有 API 暴力，但在 RealityKit 内部会触发部分纹理卸载
        let notification = NSNotification.Name("_UIApplicationWillAddDeallocationMonitorNotification")
        NotificationCenter.default.post(name: notification, object: nil)
        
        // 2. 强制垃圾回收 Swift 的 ARC 引用（虽然 ARC 是自动的，但这样可以确保闭包引用的断开）
        // 我们手动调用一次异步空闭包，有时能触发 RunLoop 的清理
        DispatchQueue.main.async { [weak self] in
            _ = self?.arView
        }
    }

    // 【添加】：彻底清理资源的函数
    private func clearAllARResources() {
        print("⚠️ 执行完整内存清理...")

        // 1. 取消动画订阅（原来漏掉了！）
        characterMoveSubscription?.cancel()
        characterMoveSubscription = nil

        // 2. 清理所有灯光定时器（原来漏掉了！）
        for (_, timer) in lightTimers {
            timer.invalidate()
        }
        lightTimers.removeAll()

        // 3. 关闭所有活跃灯光，断开 Entity 引用
        for (key, light) in activeLights {
            light.removeFromParent()
        }
        activeLights.removeAll()

        // 4. 停止所有动画
        for part in animatedParts {
            part.stopAllAnimations()
        }
        for part in currentParts {
            part.stopAllAnimations()
        }

        // 5. 深度剥离材质，断开 GPU 纹理引用
        func deepStrip(_ entity: Entity) {
            if let modelEntity = entity as? ModelEntity {
                modelEntity.model?.materials = []
            }
            for child in entity.children {
                deepStrip(child)
            }
        }

        // 6. 移除所有锚点
        arView?.scene.anchors.forEach { anchor in
            deepStrip(anchor)
            anchor.removeFromParent()
        }
        arView?.scene.anchors.removeAll()

        // 7. 清空所有本地引用
        currentParts.removeAll(keepingCapacity: false)
        animatedParts.removeAll(keepingCapacity: false)
        originalTransforms.removeAll(keepingCapacity: false)
        highlightedOutline?.removeFromParent()
        highlightedOutline = nil
        highlightedPart = nil
        rootEntity = nil
        currentAnchor = nil
        characterRoot = nil
        isCharacterMode = false
        isCharacterMoving = false
        isExploded = false
        isModelLoading = false  // 关键！防止清理后加载锁卡死

        onTargetImageFound?(false)
        UIApplication.shared.perform(Selector(("_performMemoryWarning")))

        print("✅ 清理完成")
    }

    // 【添加】：退出页面时的总销毁
    func prepareForDeinit() {
        print("ScanView 销毁：正在彻底关闭 AR 会话")
        detectionTimer?.invalidate()
        detectionTimer = nil
        arView?.session.pause()
        arView?.session.delegate = nil
        clearAllARResources()
        arView?.removeFromSuperview()
        arView = nil
    }

    func setupHandPoseDetection(arView: ARView) {
        handPoseRequest.maximumHandCount = 1
        // 【修改】：赋值给成员变量 timer
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, let arView = self.arView else { return }
            guard let frame = arView.session.currentFrame else { return }
            let pixelBuffer = frame.capturedImage

            do {
                try self.handPoseSequenceHandler.perform([self.handPoseRequest], on: pixelBuffer)
                guard let observation = self.handPoseRequest.results?.first else {
                    self.resetAllLights()
                    return
                }
                let fingerTipPoints = try observation.recognizedPoints(.indexFinger)
                guard let tipPoint = fingerTipPoints[.indexTip], tipPoint.confidence > 0.3 else {
                    self.resetAllLights()
                    return
                }

                let camera = frame.camera
                let tip3D = camera.transform * SIMD4<Float>(
                    Float(tipPoint.location.x - 0.5),
                    Float(tipPoint.location.y - 0.5),
                    -0.2,
                    1.0
                )
                let tipPos = SIMD3<Float>(tip3D.x, tip3D.y, tip3D.z)

                var currentHitEntities = Set<ModelEntity>()
                for entity in self.currentParts {
                    let isLightPart: Bool
                    if let anchor = self.currentAnchor, let config = self.modelRegistry[anchor.name], config.lightParts?.contains(entity.name) == true {
                        isLightPart = true
                    } else if self.animatedModelRegistry.values.contains(where: { $0.lightParts?.contains(entity.name) == true }) {
                        isLightPart = true
                    } else {
                        isLightPart = false
                    }

                    if isLightPart {
                        let distance = simd_distance(entity.position(relativeTo: nil), tipPos)
                        if distance < 0.15 {
                            currentHitEntities.insert(entity)
                        }
                    }
                }
                self.processLighting(for: currentHitEntities)
            } catch {
                self.resetAllLights()
            }
        }
    }

    private func processLighting(for currentHits: Set<ModelEntity>) {
        for entity in lastHitEntities {
            if !currentHits.contains(entity) {
                togglePointLight(for: entity, isOn: false)
                togglePLight(for: entity, isOn: false)
            }
        }
        for entity in currentHits {
            togglePointLight(for: entity, isOn: true)
            togglePLight(for: entity, isOn: true)
        }
        lastHitEntities = currentHits
    }

    private func togglePointLight(for entity: ModelEntity, isOn: Bool) {
        if isOn {
            if activeLights[entity] == nil {
                let light = PointLight()
                light.light.color = .orange
                light.light.intensity = 500
                light.light.attenuationRadius = 0.04
                
                
                let bounds = entity.visualBounds(relativeTo: nil)
                let top = bounds.max.y
                
                
                entity.addChild(light)
                light.position = [0, top + 2, 20]
                activeLights[entity] = light

                if var model = entity.model {
                    for i in 0..<model.materials.count {
                        if var pMat = model.materials[i] as? PhysicallyBasedMaterial {
                            pMat.emissiveIntensity = 2.0
                            model.materials[i] = pMat
                        }
                    }
                    entity.model = model
                }
            }
        } else {
            if let light = activeLights[entity] {
                light.removeFromParent()
                activeLights.removeValue(forKey: entity)

                if var model = entity.model {
                    for i in 0..<model.materials.count {
                        if var pMat = model.materials[i] as? PhysicallyBasedMaterial {
                            pMat.emissiveIntensity = 0.0
                            model.materials[i] = pMat
                        }
                    }
                    entity.model = model
                }
            }
        }
    }
    
    private func togglePLight(for entity: ModelEntity, isOn: Bool) {
        if isOn {
            if activeLights[entity] == nil {
                let light = PointLight()
                light.light.color = .orange
                light.light.intensity = 600
                light.light.attenuationRadius = 0.005
                
                let bounds = entity.visualBounds(relativeTo: entity)
                // 计算包围盒的中心点
                let center = (bounds.min + bounds.max) / 2.0
                // 将灯光平移到这个中心
                light.position = center
                
                entity.addChild(light)
                activeLights[entity] = light

                if var model = entity.model {
                    for i in 0..<model.materials.count {
                        if var pMat = model.materials[i] as? PhysicallyBasedMaterial {
                            pMat.emissiveIntensity = 2.0
                            model.materials[i] = pMat
                        }
                    }
                    entity.model = model
                }
            }
        } else {
            if let light = activeLights[entity] {
                light.removeFromParent()
                activeLights.removeValue(forKey: entity)

                if var model = entity.model {
                    for i in 0..<model.materials.count {
                        if var pMat = model.materials[i] as? PhysicallyBasedMaterial {
                            pMat.emissiveIntensity = 0.0
                            model.materials[i] = pMat
                        }
                    }
                    entity.model = model
                }
            }
        }
    }
    
    

    private func resetAllLights() {
        for (entity, _) in activeLights {
            if let mEntity = entity as? ModelEntity {
                togglePointLight(for: mEntity, isOn: false)
                togglePLight(for: mEntity, isOn: false)
            }
        }
        lastHitEntities.removeAll()
    }

    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let imageAnchor = anchor as? ARImageAnchor else { continue }
            let imageName = imageAnchor.referenceImage.name ?? ""
            
            print("识别到图片: \(imageName)") // 调试用
            
            DispatchQueue.main.async {
                
                // 2. 根据注册表判断类型
                if self.characterRegistry.keys.contains(imageName) {
                    // 如果是人物
                    self.onTargetImageFound?(true) // 显示摇杆
                    self.addCharacterModel(for: imageAnchor)
                } else if self.modelRegistry.keys.contains(imageName) {
                    // 如果是普通建筑
                    self.onTargetImageFound?(false) // 隐藏摇杆
                    self.addModel(for: imageAnchor)
                } else if self.animatedModelRegistry.keys.contains(imageName) {
                    // 如果是动画模型
                    self.onTargetImageFound?(false)
                    self.addAnimatedModel(for: imageAnchor)
                }
            }
            
        }
    }
    
    
    // 可选：如果图片丢失（脱离视野），隐藏摇杆
//    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
//        for anchor in anchors {
//            if let imageAnchor = anchor as? ARImageAnchor {
//                if imageAnchor.referenceImage.name == "宫灯" {
//                    DispatchQueue.main.async {
//                        self.onTargetImageFound?(false) // 通知 UI 隐藏摇杆
//                    }
//                }
//            }
//        }
//    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                
//                // 找到对应这个锚点的 Entity
//                if let anchorEntity = arView?.scene.anchors.first(where: { $0.anchorIdentifier == imageAnchor.identifier }) {
//    
//                    // 如果图片在镜头里，显示模型；离开了，隐藏模型
//                    // imageAnchor.isTracked 是系统自动判断图片是否在视野内的布尔值
//                    anchorEntity.isEnabled = imageAnchor.isTracked
//    
//                    // 同步更新 SwiftUI 的 UI 状态（比如摇杆的显隐）
//                    if imageAnchor.referenceImage.name == "宫灯" {
//                        DispatchQueue.main.async {
//                            self.onTargetImageFound?(imageAnchor.isTracked)
//                        }
//                    }
//                }
                
                if !imageAnchor.isTracked {
                            print("❌ 图片丢失，移除锚点以备下次重新识别")
                            
                            // 立即从 Session 中移除这个锚点
                            session.remove(anchor: imageAnchor)
                            
                            DispatchQueue.main.async {
//                                // 清理掉屏幕上的模型
//                                self.clearAllARResources()
//                                // 确保 UI 也隐藏
//                                self.onTargetImageFound?(false)
                                NotificationCenter.default.post(name: .forceCleanupAR, object: nil)
                            }
                        }
            }
        }
    private func addModel(for imageAnchor: ARImageAnchor) {
        guard !isModelLoading else { return }
        isModelLoading = true
        guard let arView = arView else { return }
        let imageName = imageAnchor.referenceImage.name ?? ""
        guard let config = modelRegistry[imageName] else { return }
        clearAllARResources()
        journeyRecorder?.recordScannedImage(imageName)

        // 【添加】：虽然上面写了清理，但在此处做二次检查，确保旧锚点被移除
        if let anchor = currentAnchor { arView.scene.removeAnchor(anchor) }

        let anchor = AnchorEntity(anchor: imageAnchor)
        currentAnchor = anchor
        currentAnchor?.name = imageName
        let root = ModelEntity()
        root.generateCollisionShapes(recursive: true)
        rootEntity = root
        anchor.addChild(root)
        arView.installGestures([.rotation, .scale, .translation], for: root)
        for partName in config.parts {
            do {
                let part = try ModelEntity.loadModel(named: partName)
                part.name = partName
                part.scale = config.scale
                part.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                part.generateCollisionShapes(recursive: true)
                root.addChild(part)
                currentParts.append(part)
                originalTransforms[part] = part.transform
            } catch {
                let box = ModelEntity(mesh: .generateBox(size: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                root.addChild(box)
            }
        }
        arView.scene.addAnchor(anchor)
        isModelLoading = false
    }

    private func addAnimatedModel(for imageAnchor: ARImageAnchor) {
        guard !isModelLoading else { return }
        isModelLoading = true
        guard let arView = arView else { return }
        let imageName = imageAnchor.referenceImage.name ?? ""
        guard let config = animatedModelRegistry[imageName] else { return }

        animatedParts.removeAll()
        clearAllARResources()

        journeyRecorder?.recordScannedImage(imageName)
        let anchor = AnchorEntity(anchor: imageAnchor)
        arView.scene.addAnchor(anchor)

        // 遍历 dc1, dc2, ... dc9
        for partName in config.parts {
            do {
                // 1. 加载模型（带动画的 Entity）
                let part = try Entity.load(named: partName)
                part.name = partName
                
                
                part.scale = config.scale * 0.7
                part.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                
                
                if imageName == "铛铛车" {
                    part.orientation = simd_quatf(angle: .pi / 2, axis: [0,0,1]) *
                                                  simd_quatf(angle: .pi, axis: [1, 0, 0])
                    
                    
                }
                
                anchor.addChild(part)

                // 2. 【核心修复】：定义一个递归闭包，深入层级寻找真正的 ModelEntity
                func activateLightRecursively(_ currentEntity: Entity, assignedName: String) {
                    // 如果这个子物体是 ModelEntity，它才有 .model 属性，才能亮灯
                    if let modelPart = currentEntity as? ModelEntity {
                        
                        modelPart.name = assignedName
                        
                        // 存入数组，保证点击高亮和灯光函数能识别它
                        if !self.animatedParts.contains(modelPart) {
                            modelPart.generateCollisionShapes(recursive: false)
                            self.animatedParts.append(modelPart)
                        }

                        // 检查这个零件是否在 lightParts 名单里
                        if let lightParts = config.lightParts, lightParts.contains(partName) {
                            if imageName == "铛铛车" {
                                // 铛铛车：执行第4秒闪烁逻辑
                                self.setupDangdangBlink(for: modelPart)
                            } else {
                                // 其他（如“灯”）：直接常亮
                                self.togglePLight(for: modelPart, isOn: true)
                            }
                        }
                    }
                    // 继续往深层找
                    for child in currentEntity.children {
                        activateLightRecursively(child, assignedName: assignedName)
                    }
                }
            
                // 开始递归
                activateLightRecursively(part, assignedName: partName)

                // 3. 播放动画
                if config.loopAnimation {
                    for animation in part.availableAnimations {
                        part.playAnimation(animation.repeat(duration: .infinity))
                    }
                }

            } catch {
                print("加载失败: \(partName)")
            }
        }
        isModelLoading = false
    }
    
    
    // 人物专用加载逻辑
        private func addCharacterModel(for imageAnchor: ARImageAnchor) {
            guard !isModelLoading else { return }
            isModelLoading = true
            guard let arView = arView, let config = characterRegistry[imageAnchor.referenceImage.name ?? ""] else { return }
            
            let anchor = AnchorEntity(anchor: imageAnchor)
            let root = Entity()
            characterRoot = root
            anchor.addChild(root)
            
            for partName in config.parts {
                if let part = try? Entity.load(named: partName) {
                    part.name = partName
                    part.scale = config.scale
                    // 强制正立：无论识别图角度，初始姿态垂直向上
                    part.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                    processCharacterPartsRecursively(part, partName: partName, config: config)
                    
                    if partName == config.lightPart {
                        let light = PointLight()
                        light.light.color = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
                        light.light.intensity = 1500
                        light.light.attenuationRadius = 0.6
                        light.position = [0, -0.3, 0.7]
                                    
                                    
                        
                        part.addChild(light)
                        
                    }
                    root.addChild(part)
                }
            }
            arView.scene.addAnchor(anchor)
            
            // 核心：启动摇杆监听
            // 核心：启动摇杆监听循环
                characterMoveSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                    guard let self = self, let root = self.characterRoot else { return }
                    
                    // 1. 设置灵敏度阈值 (防止微小抖动)
                    let threshold: CGFloat = 0.1
                    let currentVector = self.joystickVector
                    let magnitude = sqrt(pow(currentVector.x, 2) + pow(currentVector.y, 2))
                    
                    if magnitude > threshold {
                        // --- 移动状态：执行位移和动画 ---
                        
                        // 2. 优化速度计算 (使用 event.deltaTime 确保帧率同步，不卡顿)
                        // 增加速度系数，0.5 代表每秒移动 0.5米
                        let speedFactor: Float = 3
                        let dx = Float(currentVector.x / 70.0) * speedFactor * Float(event.deltaTime)
                        let dz = Float(-currentVector.y / 70.0) * speedFactor * Float(event.deltaTime)
                        
                        root.position += [dx, -dz, 0]
                        
                        // 3. 计算旋转 (角度平滑)
                        let angle = atan2(dx, dz) + .pi
                        root.orientation = simd_quatf(angle: angle, axis: [0, 0, 1])
                        
                        // 4. 动画状态锁：只有从“静止”变为“移动”时才播放一次 repeat 动画
                        if !self.isCharacterMoving {
                            self.isCharacterMoving = true
                            root.children.forEach { entity in
                                if let anim = entity.availableAnimations.first {
                                    entity.playAnimation(anim.repeat())
                                }
                            }
                        }
                    } else {
                        // --- 静止状态：停止动画 ---
                        if self.isCharacterMoving {
                            self.isCharacterMoving = false
                            root.children.forEach { $0.stopAllAnimations() }
                        }
                    }
                }
            isModelLoading = false
        }
    
    private func processCharacterPartsRecursively(_ entity: Entity, partName: String, config: CharacterConfig) {
        if let modelEntity = entity as? ModelEntity {
            // 开启碰撞，否则 handleTap 找不到它
            modelEntity.generateCollisionShapes(recursive: false)
            
            if entity.name == partName {
                // 将人物部件也加入检测列表，这样点击逻辑才能识别
                if !self.animatedParts.contains(modelEntity) {
                    self.animatedParts.append(modelEntity)
                }
            }
            
            // 3. 【灯光逻辑】：使用和你建筑一样的中心点点灯函数
            if partName == config.lightPart {
                // 这里调用你已经写好的 togglePLight，它会自动计算包围盒中心
                self.togglePLight(for: modelEntity, isOn: true)
            }
        }
        
        for child in entity.children {
            processCharacterPartsRecursively(child, partName: partName, config: config)
        }
    }
    
    
    private func setupDangdangBlink(for entity: ModelEntity) {
        // 移除该实体旧的定时器防止叠加
        lightTimers[entity]?.invalidate()

        let startTime = CACurrentMediaTime()

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak entity] _ in
            guard let self = self, let entity = entity else { return }

            let elapsed = CACurrentMediaTime() - startTime
            // 假设总循环周期为 6 秒
            let cycleTime = elapsed.truncatingRemainder(dividingBy: 16.9)

            /* 逻辑设计：
             0.0 - 4.0: 灭
             4.0 - 4.5: 亮 (第一闪开始)
             4.5 - 5.0: 灭
             5.0 - 5.5: 亮 (第二闪开始)
             5.5 - 6.0: 灭
            */

            if (cycleTime >= 4.0 && cycleTime < 4.5) || (cycleTime >= 5.0 && cycleTime < 5.5) {
                self.togglePLight(for: entity, isOn: true)
            } else {
                self.togglePLight(for: entity, isOn: false)
            }
        }

        lightTimers[entity] = timer
    }
    
    

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        let location = gesture.location(in: arView)
        
        // 1. 取得點擊到的底層節點
        var current: Entity? = arView.entity(at: location)
        
        // 獲取所有合法的零件名稱清單
        let allValidNames = (modelRegistry.values.flatMap { $0.parts }) +
                           (animatedModelRegistry.values.flatMap { $0.parts }) +
                           (characterRegistry.values.flatMap { $0.parts })

        print("--- 開始追溯 ---")
        
        while let checkEntity = current {
            print("檢查層級: \(checkEntity.name)")
            
            if allValidNames.contains(checkEntity.name) {
                print("🎯 匹配零件名成功: \(checkEntity.name)")
                
                // --- 【高亮邏輯：改回你原本正確的寫法】 ---
                if let target = checkEntity.findFirstModelEntity() {
                    handleHighlight(for: target)
                }
                
                // --- 【彈窗與資訊部分：核心修正】 ---
                // 1. 這裡直接發送追溯到的「正主」名字（如 "dl1"）
                // 2. 確保你的 UI 端是根據這個 "partName" 去 Registry 字典裡查表顯示文字的
                NotificationCenter.default.post(
                    name: NSNotification.Name("showPartInfo"),
                    object: nil,
                    userInfo: ["partName": checkEntity.name]
                )
                
                return // 匹配成功，直接結束
            }
            current = checkEntity.parent
        }
        
        print("⚠️ 追溯結束，未匹配到任何零件")
    }

    private func highlightAllChildren(in root: Entity) {
        // 1. 核心：如果这个节点（不管层级多深）有模型组件，就高亮它
        if let modelEntity = root as? ModelEntity {
            // 这里的 handleHighlight 是你之前写的那个给模型套边框的函数
            self.handleHighlight(for: modelEntity)
        }
        
        // 2. 递归：只要有孩子，就继续往里钻
        for child in root.children {
            highlightAllChildren(in: child)
        }
    }



    private func handleHighlight(for part: ModelEntity) {
        removeHighlight()
        let outline = part.clone(recursive: true)
        outline.name = "highlightOutline"
        outline.generateCollisionShapes(recursive: false)
        if var materials = outline.model?.materials {
            for i in 0..<materials.count {
                materials[i] = UnlitMaterial(color: UIColor.yellow.withAlphaComponent(0.4))
            }
            outline.model?.materials = materials
        }
        outline.transform = Transform(scale: [1.05, 1.05, 1.05])
        part.addChild(outline)
        highlightedPart = part
        highlightedOutline = outline
        NotificationCenter.default.post(name: .showPartInfo, object: nil, userInfo: ["partName": part.name])
    }

    private func removeHighlight() {
        highlightedOutline?.removeFromParent()
        highlightedOutline = nil
        highlightedPart = nil
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let arView = arView else { return }
        let location = gesture.location(in: arView)
        guard arView.entity(at: location) != nil else { return }
        if isExploded { collapse() } else { explode() }
        isExploded.toggle()
    }

    private func explode() {
        guard let arView = arView, let root = rootEntity, let anchor = currentAnchor else { return }
        guard let config = modelRegistry[anchor.name] else { return }
        root.components.remove(CollisionComponent.self)
        for (i, part) in currentParts.enumerated() {
            part.generateCollisionShapes(recursive: false)
            arView.installGestures([.rotation, .scale, .translation], for: part)
            var t = part.transform
            t.translation = originalTransforms[part]!.translation + config.explodeOffsets[i]
            part.move(to: t, relativeTo: part.parent, duration: 0.6)
        }
    }

    private func collapse() {
        removeHighlight()
        guard let arView = arView, let root = rootEntity else { return }
        for part in currentParts {
            if let original = originalTransforms[part] {
                part.move(to: original, relativeTo: part.parent, duration: 0.6)
                part.components.remove(CollisionComponent.self)
            }
        }
        var minVec = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maxVec = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for part in currentParts {
            let b = part.visualBounds(relativeTo: root)
            minVec = min(minVec, b.min)
            maxVec = max(maxVec, b.max)
        }
        let size = maxVec - minVec
        let shape = ShapeResource.generateBox(size: size)
        root.components.set(CollisionComponent(shapes: [shape]))
        arView.installGestures([.rotation, .scale, .translation], for: root)
    }
    
}

// 简单的虚拟摇杆组件
struct JoystickView: View {
    @Binding var vector: CGPoint
    @State private var knobOffset: CGSize = .zero
    let radius: CGFloat = 70
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: radius * 2, height: radius * 2)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: radius * 0.8, height: radius * 0.8)
                .offset(knobOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            let limit = min(distance, radius)
                            let angle = atan2(value.translation.height, value.translation.width)
                            
                            knobOffset = CGSize(
                                width: cos(angle) * limit,
                                height: sin(angle) * limit
                            )
                            // 归一化向量 (-1 到 1)
                            vector = CGPoint(x: knobOffset.width / radius, y: knobOffset.height / radius)
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                knobOffset = .zero
                                vector = .zero
                            }
                        }
                )
        }
    }
}

struct ARRebuildingOverlay: View {
    let tramImage: String = "chetou" // 替换成你实际的铛铛车图片名
    
    @State private var dotCount = 1
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            Color(hex: "#eae8e0").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Image(tramImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                
                VStack(spacing: 8) {
                    Text("图像已离开视野")
                        .appFont(AppFont.story())
                        .foregroundColor(.black)
                    
                    HStack(spacing: 0) {
                        Text("正准备重新扫描")
                            .appFont(AppFont.story())
                            .foregroundColor(.black)
                        
//                        // 省略号动画
//                        Text(String(repeating: "·", count: dotCount))
//                            .appFont(AppFont.story())
//                            .foregroundColor(.black)
//                            .frame(width: 60, alignment: .leading)
//                            .animation(nil, value: dotCount)
                        
                        HStack(spacing: 2) {
                                ForEach(1...6, id: \.self) { index in
                                    Text("·")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(index <= dotCount
                                            ? Color(red: 60/255, green: 60/255, blue: 60/255)
                                            : .clear)
                                }
                            }
                    }
                }
            }
        }
        .onAppear {
            dotCount = 1
            timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = dotCount >= 6 ? 1 : dotCount + 1
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
