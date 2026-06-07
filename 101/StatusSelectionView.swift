//
//  StatusSelectionView.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//

import SwiftUI

struct StatusSelectionView: View {

    @EnvironmentObject var appState: AppState

    // 动画状态
    @State private var animateTransition = false
    @State private var showButtons = true

    // 放大中心坐标
    let zoomCenter = CGPoint(x: UIScreen.main.bounds.width * 0.5,
                             y: UIScreen.main.bounds.height * 0.5)

    var body: some View {
        ZStack {
            // 背景图
            Image("statusBackground")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width,
                       height: UIScreen.main.bounds.height)
                .offset(x: animateTransition ? -(zoomCenter.x - UIScreen.main.bounds.width/2)
                                             : 0,
                        y: animateTransition ? -(zoomCenter.y - UIScreen.main.bounds.height/2)
                                             : 0)
                .scaleEffect(animateTransition ? 2.5 : 1)
                .opacity(animateTransition ? 0 : 1)
                .animation(.easeInOut(duration: 1.0), value: animateTransition)
                .ignoresSafeArea()

            // 按钮
            if showButtons {
                VStack(spacing: 30) {
                    Button(action: {
                        // 点击 "旅程中"
                        showButtons = false
                        withAnimation(.easeInOut(duration: 1.0)) {
                            animateTransition = true
                        }
                        // 延迟切换页面
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // ✨ 修改：使用 withAnimation 包裹状态切换，使 transition 生效
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                appState.currentScreen = .home
                            }
                        }
                    }) {
                        Text("旅程中")
                            .appFont(AppFont.title())
                            .foregroundColor(.black)
                    }.offset(x: -110, y: -130)

                    Button(action: {
                        // ✨ 修改：同样的，跳转到个人中心也加上平滑动画
                        withAnimation(.spring()) {
                            appState.currentScreen = .personal
                        }
                    }) {
                        Text("非旅程中")
                            .appFont(AppFont.title())
                            .foregroundColor(.black)
                            .rotationEffect(.degrees(7))
                    }.offset(x: -100, y: -50)
                }
            }
        }
    }
}
