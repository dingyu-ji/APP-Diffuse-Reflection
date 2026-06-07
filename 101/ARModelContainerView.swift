//
//  ARModelContainerView.swift
//  101
//
//  Created by 刘明 on 05/03/2026.
//

import SwiftUI
import RealityKit


struct ARModelContainerView: UIViewRepresentable {

    let rootEntity: ModelEntity

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {

        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)

        // 关闭 AR，使用固定相机
        arView.cameraMode = .nonAR

        // 固定相机位置
        let camera = PerspectiveCamera()
        camera.position = [0, 0, 1.2]

        let cameraAnchor = AnchorEntity(world: [0, 0, 0])
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        // 创建模型 Anchor
        let anchor = AnchorEntity(world: [0, 0, 0])
        arView.scene.addAnchor(anchor)

        // 克隆模型
        let model = rootEntity.clone(recursive: true)
        anchor.addChild(model)

        // 自动缩放并居中
        let bounds = model.visualBounds(relativeTo: model)
        
        let maxDimension = max(bounds.extents.x,
                               bounds.extents.y,
                               bounds.extents.z)

        if maxDimension > 0 {
            let scale: Float = 0.8 / maxDimension
            model.scale = SIMD3<Float>(repeating: scale)
            model.position = -bounds.center * scale
        }

        // ✅ 设置初始俯视角（平视略俯视）
        let initialPitch: Float = -.pi / 2 // 约 22.5° 俯视
        model.orientation = simd_quatf(angle: initialPitch, axis: [1,0,0])

        context.coordinator.model = model
        context.coordinator.initialPitch = initialPitch

        // 添加拖动手势（旋转模型）
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        arView.addGestureRecognizer(pan)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject {

        var model: ModelEntity?
        var initialPitch: Float = 0
        private var currentAngle: Float = 0

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let model = model else { return }

            let translation = gesture.translation(in: gesture.view)
            let delta = Float(translation.x) * 0.005

            if gesture.state == .changed {
                currentAngle += delta

                // 保留初始俯视角，手指滑动只绕 Y 轴旋转
                let yRotation = simd_quatf(angle: currentAngle, axis: [0,1,0])
                let xRotation = simd_quatf(angle: initialPitch, axis: [1,0,0])
                model.orientation = simd_mul(yRotation, xRotation)

                gesture.setTranslation(.zero, in: gesture.view)
            }
        }
    }
}

