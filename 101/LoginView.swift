//
//  LoginView.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//


import SwiftUI

struct LoginView: View {

    @EnvironmentObject var appState: AppState

    @State private var isZoomedOut = false

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        ZStack {

            // 背景色
            Color(hex: "#eae8e0")
                .ignoresSafeArea()

            GeometryReader { geo in

                ZStack {

                    // -------------------------
                    // 巴士背景图（保持不变）
                    // -------------------------
                    Image("busBackground")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(isZoomedOut ? 1.4 : 2.5)
                        .offset(
                            x: isZoomedOut ? geo.size.width * 0.05 : geo.size.width * 0.1,
                            y: isZoomedOut ? 15 : -280
                        )
                        .animation(.easeInOut(duration: 0.8), value: isZoomedOut)

                    // -------------------------
                    // 登录 UI（拆成三个独立模块）
                    // -------------------------
                    if !isZoomedOut {

                        ZStack {

                            // 1️⃣ Avatar（独立）
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 90, height: 255)
                                .overlay(Text("Avatar"))
                                .transformEffect(
                                    CGAffineTransform(a: 1, b: 0, c: -0.25, d: 1, tx: 0, ty: 0)
                                )
                                .position(
                                    x: geo.size.width * 0.61,
                                    y: geo.size.height * 0.33
                                )

                            // 2️⃣ 输入框（独立）
                            VStack(spacing: 12) {

                                TextField("Username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 230)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)

                                SecureField("Password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 230)
                            }
                            .position(
                                x: geo.size.width * 0.6,
                                y: geo.size.height * 0.62
                            )

                            // 3️⃣ Login 按钮（独立）
                            Button {
                                withAnimation {
                                    isZoomedOut = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    appState.currentScreen = .statusSelection
                                }
                            } label: {
                                Text("Login")
                                    .fontWeight(.bold)
                                    .frame(width: 60, height: 60)
                                    .background(Color(hex: "FFC300"))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .position(
                                x: geo.size.width * 0.43,
                                y: geo.size.height * 0.75
                            )

                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }
                    }

                    // -------------------------
                    // 路牌（保持不变）
                    // -------------------------
                    Image("roadSign")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width)
                        .offset(
                            x: isZoomedOut ? -geo.size.width * 0.001 : -geo.size.width
                        )
                        .animation(.easeOut(duration: 0.8), value: isZoomedOut)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// -------------------------
// 隐藏键盘
// -------------------------
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
