//
//  PersonalView.swift
//  101
//
//  Created by 刘明 on 28/02/2026.
//

import SwiftUI

struct PersonalView: View {
    @EnvironmentObject var journeyRecorder: JourneyRecorder
    @EnvironmentObject var appState: AppState
    
    @State private var selectedCardID: Int? = nil
    @State private var showBigCard = false
    @State private var cardScale = 0.1
    @State private var cardRotation = -90.0

    // 容器与卡片宽度设定
    private let containerWidth: CGFloat = UIScreen.main.bounds.width - 65
    private let containerHeight: CGFloat = 550
    private let itemWidth: CGFloat = UIScreen.main.bounds.width - 110 // 限定卡片宽度

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // 背景图
                Image("personalBK")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 1. 顶部：自定义返回按钮
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                appState.currentScreen = .statusSelection
                            }
                        } label: {
                            Image("backButton")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        Spacer()
                    }
                    .padding(.top, 40)
                    .padding(.leading, 30)

                    // 2. 用户信息
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户名")
                                .bold()
                                .foregroundColor(.white)
                            
                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { id in
                                    let isUnlocked = journeyRecorder.unlockedIDs.contains("\(id)")
                                    Image("Icon_气质\(id)")
                                        .resizable()
                                        .frame(width: 35, height: 35)
                                        .grayscale(isUnlocked ? 0 : 1.0)
                                        .opacity(isUnlocked ? 1.0 : 0.5)
                                        .onTapGesture {
                                            if isUnlocked {
                                                selectedCardID = id
                                                cardRotation = -90
                                                cardScale = 0.1
                                                withAnimation { showBigCard = true }
                                            }
                                        }
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 17)

                    // 3. 旅程记录列表
                    ZStack {
                        List {
                            ForEach(Array(journeyRecorder.achievements.enumerated().reversed()), id: \.element.id) { index, achievement in
                                ZStack {
                                    NavigationLink(destination: AchievementDetailView(achievement: achievement)) {
                                        EmptyView()
                                    }
                                    .opacity(0)

                                    HStack(spacing: 15) {
                                        RecordThumbnail(data: achievement.photosData.first)

                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(achievement.location)
                                                .appFont(AppFont.title())
                                                .foregroundColor(.white)

                                            HStack(spacing: 10) {
                                                if let trainData = achievement.trainThumbnailData,
                                                   let uiImage = UIImage(data: trainData) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 35, height: 35)
                                                }

                                                if !achievement.photosData.isEmpty {
                                                    Image("cameraIcon")
                                                        .resizable()
                                                        .frame(width: 40, height: 40)
                                                }

                                                if !achievement.modelNames.isEmpty {
                                                    Image("scanIcon")
                                                        .resizable()
                                                        .frame(width: 40, height: 40)
                                                }
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                    .frame(width: itemWidth)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(15)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 20, leading: (containerWidth - itemWidth)/2 - 35, bottom: 0, trailing: 0))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteAchievementById(achievement.id)
                                    } label: {
                                        Image("deleteBtn")
                                            .renderingMode(.original)
                                    }
                                    .tint(.clear)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                        .frame(width: containerWidth, height: containerHeight)
                    }
                    .padding(.top, 32)
                    .padding(.leading, 15)

                    Spacer()
                }
                
                // ✨ 3. 大图查看浮层 (已修正：按钮移至右上角且不再挤压卡片)
                if showBigCard, let id = selectedCardID {
                    ZStack {
                        Color.black.opacity(0.85)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { showBigCard = false }
                            }
                        
                        // 核心：将卡片作为主体
                        Image("Card_气质\(id)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 360)
                            .rotation3DEffect(
                                .degrees(cardRotation),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.4
                            )
                            .scaleEffect(cardScale)
                            .onAppear {
                                withAnimation(.interpolatingSpring(stiffness: 40, damping: 8)) {
                                    cardRotation = 0
                                    cardScale = 1.0
                                }
                            }
                            // 💡 使用 overlay 将按钮定位在右上角
                            .overlay(
                                Button {
                                    withAnimation { showBigCard = false }
                                } label: {
                                    Image("deleteBtn")
                                        .resizable()
                                        .frame(width: 44, height: 44) // 适当缩小按钮适配右上角
                                }
                                // 如果按钮太贴边缘，调整这里的 offset (x减小往左，y增加往下)
                                .offset(x: -15, y: 25),
                                alignment: .topTrailing
                            )
                    }
                    .zIndex(100)
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                journeyRecorder.loadAchievementsFromDisk()
            }
        }
        .transition(.move(edge: .leading))
    }

    func deleteAchievementById(_ id: UUID) {
        if let index = journeyRecorder.achievements.firstIndex(where: { $0.id == id }) {
            journeyRecorder.achievements.remove(at: index)
            journeyRecorder.saveAchievementsToDisk()
        }
    }
}

struct RecordThumbnail: View {
    let data: Data?
    var body: some View {
        if let data = data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 75, height: 75)
                .clipped()
                .cornerRadius(10)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .frame(width: 75, height: 75)
        }
    }
}
