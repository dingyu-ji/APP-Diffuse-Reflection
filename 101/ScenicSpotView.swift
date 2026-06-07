//
//  ScenicSpotView.swift
//  101
//
//  Created by 刘明 on 28/02/2026.
//


import SwiftUI
import AVKit

struct ScenicSpotView: View {

    @EnvironmentObject var journeyRecorder: JourneyRecorder

    let spot: ScenicSpot
    var onClose: () -> Void

    @State private var player: AVPlayer? = nil

    // 你指定的十六进制颜色 #eae8e0
    let themeColor = Color(red: 234/255, green: 232/255, blue: 224/255)

    var body: some View {
        ZStack {
            // 1. 底色层
            themeColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // 自定义返回按钮图片
                Button(action: {
                    onClose()
                }) {
                    Image("backButton") // 替换为你的返回图片名
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {

                        Text(spot.name)
                            .appFont(AppFont.title())
                            .bold()
                            .padding(.horizontal, 20)

                        // 2. 文字与动态横线逻辑
                        Text(spot.description)
                            .appFont(AppFont.story())
                            .lineSpacing(12) // 设定行间距
                            .padding(.vertical, 4)
                            .padding(.horizontal, 20)
                            .background(
                                // 使用 GeometryReader 自动填满文字区域
                                VStack(spacing: 0) {
                                    // 计算行高：字体大小(18) + 行间距(12) = 30
                                    ForEach(0..<100, id: \.self) { _ in
                                        VStack(spacing: 0) {
                                            Spacer().frame(height: 29) // 略小于行高
                                            Image("line") // 你的横线图片
                                                .resizable()
                                                .frame(height: 1.5)
                                        
                                        }
                                    }
                                }
                                .clipped() // 关键：确保横线不超出文字底边界
                            )

                        // 3. 视频 + 覆盖遮罩
                        if let player = player {
                            ZStack {
                                // 下层：视频
                                VideoPlayer(player: player)
                                    .frame(height: 220)
                                    .cornerRadius(8)

                                // 上层：手绘遮罩（中间透明）
                                Image("vidmask") // 替换为你的遮罩图片名
                                    .resizable()
                                    .aspectRatio(contentMode: .fill) // 不拉伸
                                    .frame(height: 240) // 略大于视频高度，产生溢出感
                                    .allowsHitTesting(false) // 允许点击穿透到下面的视频
                            }
                            .onAppear {
                                player.play()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            journeyRecorder.recordAction("查看：\(spot.name)介绍")
            if let path = Bundle.main.path(forResource: spot.videoName, ofType: "mp4") {
                player = AVPlayer(url: URL(fileURLWithPath: path))
                player?.play()
            }
        }
    }
}
