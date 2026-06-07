//
//  LoadingView.swift
//  101
//
//  Created by 刘明 on 02/03/2026.
//

import SwiftUI

struct LoadingView: View {
    @ObservedObject var loader: SummaryLoader

    // 建筑配置：使用你第二段代码的图片名，位置参数(t)保持一致
    let buildingConfigs: [(t: CGFloat, offset: CGFloat, name: String, size: CGFloat)] = [
        (0.15, -100, "tamcai", 100),
        (0.30, 100, "ggcai", 100),
        (0.45, -110, "ttcai", 110),
        (0.60, 100, "qcai", 100),
        (0.75, -105, "jscai", 105),
        (0.90, 110, "glcai", 100)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. 背景图 (铺满全屏)
                Image("loadBK")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                // 2. 建筑层 (不偏移，严格遵循 RoadMath 的原始路径)
                ForEach(0..<buildingConfigs.count, id: \.self) { index in
                    let config = buildingConfigs[index]
                    let pt = RoadMath.point(at: config.t, in: geo.size)
                    let angle = RoadMath.angle(at: config.t, in: geo.size).radians

                    // 计算垂直于路径的偏移位置
                    let x = pt.x + CGFloat(cos(angle + .pi / 2)) * config.offset
                    let y = pt.y + CGFloat(sin(angle + .pi / 2)) * config.offset

                    // 第一段代码的变色逻辑：车头 y 坐标小于建筑 y 坐标时变色
                    let busPos = RoadMath.point(at: loader.progress, in: geo.size)
                    let isColored = busPos.y < pt.y

                    Image(config.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: config.size, height: config.size)
                        .saturation(isColored ? 1.0 : 0.0)
                        .opacity(isColored ? 1.0 : 0.6)
                        .position(x: x, y: y)
                        .animation(.easeInOut(duration: 0.3), value: isColored)
                }

                // 3. 动态偏移组 (只针对车和文字进行平移)
                Group {
                    // 文字层：沿路径排列，车开过的地方消失
                    TextLayer(busY: RoadMath.point(at: loader.progress, in: geo.size).y, size: geo.size)

                    // 红色客车：完全复刻第一段的样式和动画
                    BusView()
                        .rotationEffect(RoadMath.angle(at: loader.progress, in: geo.size) + Angle(degrees: 180))
                        .position(RoadMath.point(at: loader.progress, in: geo.size))
                        .animation(.linear(duration: 0.1), value: loader.progress)
                }
                .offset(x: 20) // <--- 这里控制车和文字向右平移的距离
            }
        }
    }
}

// MARK: - 路径数学逻辑 (完全抄自第一段代码，确保轨迹 100% 一致)
struct RoadMath {
    static let p0 = CGPoint(x: 0.5, y: 0.0)
    static let p1 = CGPoint(x: 0.8, y: 0.33)
    static let p2 = CGPoint(x: 0.2, y: 0.66)
    static let p3 = CGPoint(x: 0.5, y: 1.0)

    static func point(at t: CGFloat, in size: CGSize) -> CGPoint {
        let x = bezier(t, p0.x, p1.x, p2.x, p3.x) * size.width
        let y = bezier(t, p0.y, p1.y, p2.y, p3.y) * size.height
        return CGPoint(x: x, y: y)
    }

    static func bezier(_ t: CGFloat, _ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
        let u = 1 - t
        return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
    }

    static func angle(at t: CGFloat, in size: CGSize) -> Angle {
        let delta: CGFloat = 0.01
        let pt1 = point(at: max(0, t - delta), in: size)
        let pt2 = point(at: min(1, t + delta), in: size)
        return Angle(radians: Double(atan2(pt2.y - pt1.y, pt2.x - pt1.x)))
    }
}

// MARK: - 文字层 (完全抄自第一段代码)
struct TextLayer: View {
    var busY: CGFloat
    var size: CGSize
    let text = "L O A D I N G . . . . . . . . . . . . . . . . . . . . . "

    var body: some View {
        Canvas { context, size in
            let chars = Array(text)
            for i in 0..<chars.count {
                let t = CGFloat(i) / CGFloat(chars.count)
                let pt = RoadMath.point(at: t, in: size)

                // 核心逻辑：文字在车头前方(pt.y > busY)时可见，车开过后消失
                // 注意：由于第一段代码是从 y=0 开往 y=1，所以是 pt.y > busY
                if pt.y > busY {
                    let angle = RoadMath.angle(at: t, in: size)
                    var charCtx = context
                    charCtx.translateBy(x: pt.x, y: pt.y)
                    charCtx.rotate(by: angle)
                    let resolved = context.resolve(Text(String(chars[i]))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.black.opacity(0.6)))
                    charCtx.draw(resolved, at: .zero, anchor: .center)
                }
            }
        }
    }
}

// MARK: - 红色客车视图 (完全抄自第一段代码)
struct BusView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.9, green: 0.3, blue: 0.24))
                .frame(width: 28, height: 50)
            VStack(spacing: 6) {
                Rectangle().fill(Color.white.opacity(0.9)).frame(width: 20, height: 10).cornerRadius(2)
                Rectangle().fill(Color.white.opacity(0.9)).frame(width: 20, height: 16).cornerRadius(2)
            }
        }
    }
}

