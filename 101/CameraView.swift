//
//  CameraView.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//

import SwiftUI
import AVFoundation

// ✅ 1. 核心形状：反向遮罩（用于在图片上抠洞）
struct InvertedCircleShape: Shape {
    var center: CGPoint
    var radius: CGFloat
    
    // 让半径支持动画
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect) // 满屏矩形
        let hole = Path { p in
            // 在矩形里抠一个圆洞
            p.addArc(center: center,
                     radius: max(0, radius),
                     startAngle: .zero,
                     endAngle: .degrees(360),
                     clockwise: true)
        }
        path.addPath(hole) // 使用 even-odd 规则抠出圆洞
        return path
    }
}

struct CameraView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var journeyRecorder: JourneyRecorder
    
    @State private var session = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var showAlbum = false
    @State private var captureDelegate: PhotoCaptureDelegate?
    @State private var flashOpacity: Double = 0

    // --- ✅ 新增：内部图片抠洞转场动画状态 ---
    @State private var maskRadius: CGFloat = 0 // 初始半径为 0（洞是关着的，显示完整图片）
    @State private var isAnimationFinished = false // 动画是否结束

    var body: some View {
        ZStack {
            // ✅ 2. 【最底层】：相机预览
            // 它在页面一加载就开始初始化，动画过程中它一直在后台热身
            CameraPreview(session: session)
                .ignoresSafeArea()

            // ✅ 3. 【中间层】：UI 按钮和闪烁层
            // 只有当动画彻底结束后，才显示这些交互按钮，防止动画过程中误触
            if isAnimationFinished {
                // 拍照闪烁层
                Color.white.opacity(flashOpacity).ignoresSafeArea()

                // 拍照按钮
                Button(action: { takePhoto() }) {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                        .background(Circle().fill(Color.white.opacity(0.3)))
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 160)

                // 左下角相册入口
                albumButton
                    .position(x: 90, y: UIScreen.main.bounds.height - 160)

                // 🔙 返回按钮
                Button(action: {
                    // 切回菜单页
                    appState.currentScreen = .actionSelection
                }) {
                    Image("backButton") // 确保你有这个资产
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .position(x: 60, y: 50)
            }

            // ✅ 4. 【最顶层】：转场占位图片层 (基于你的要求，不使用米色背景)
            // 它的存在让用户在相机初始化真空期看到的是一张干净的图片
            if !isAnimationFinished {
                // 🔥 关键：在这里加载你的图片
                // 确保你项目资产里有一张全屏的图片，例如叫 "transitionPhoto"
                Image("transitionPhoto") // 👈 替换成你真实的图片资产名称
                    .resizable()
                    .scaledToFill()
                    // 🔥 核心：在这个图片上应用“反向圆洞遮罩”
                    .mask(
                        InvertedCircleShape(
                            // 洞的中心点设在屏幕中央，可以设在原本按钮的位置，这里设中央
                            center: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY),
                            radius: maskRadius
                        )
                        .ignoresSafeArea()
                    )
            }
        }
        .onAppear {
            // 1. 启动相机硬件
            setupSession()
            
            // 2. ✅ 触发：给相机硬件 0.2 秒时间热身
            // 确保抠洞的一瞬间，底下露出的不是黑屏，而是已经有画面的实景
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 3. 计算扩满屏幕所需的半径
                let screen = UIScreen.main.bounds
                let finalRadius = sqrt(pow(screen.width, 2) + pow(screen.height, 2))
                
                // 4. 执行抠洞动画 (0.6秒)
                // 半径从 0 扩散到 finalRadius，图片中间会出一个圆洞并扩满全屏
                withAnimation(.easeIn(duration: 0.6)) {
                    maskRadius = finalRadius
                }
                
                // 5. 动画结束，移除图片占位，显示 UI 按钮
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isAnimationFinished = true
                }
            }
        }
        .fullScreenCover(isPresented: $showAlbum) {
            AlbumView().environmentObject(photoStore)
        }
    }

    // 相册按钮逻辑提取
    private var albumButton: some View {
        Group {
            if let lastPhoto = photoStore.photos.first,
               let image = photoStore.loadImage(for: lastPhoto) {
                Button(action: { showAlbum = true }) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(8)
                }
            } else {
                Button(action: { showAlbum = true }) {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - 设置相机 (保持不变)
    func setupSession() {
        if session.isRunning { return } // 防止重复启动
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    // MARK: - 拍照 (保持不变)
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate(photoStore: photoStore, journeyRecorder: journeyRecorder)
        captureDelegate = delegate
        withAnimation(.easeIn(duration: 0.1)) { flashOpacity = 0.8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 0 }
        }
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
}
