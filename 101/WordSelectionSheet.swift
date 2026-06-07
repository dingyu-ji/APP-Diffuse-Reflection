//
//  WordSelectionSheet.swift
//  101
//
//  Created by 刘明 on 08/03/2026.
//


import SwiftUI

struct WordSelectionSheet: View {
    @EnvironmentObject var galleryStore: GalleryStore
    var paragraph: StoryParagraph

    @State var selected: Set<String> = []
    var onFinish: ([String]) -> Void

    // ✨ 引入第一段代码中的视觉参数
    let themeColor = Color(red: 234/255, green: 232/255, blue: 224/255)
    let fontSize: CGFloat = 18
    let lineSpacing: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("选择关键词")
                    .appFont(AppFont.title())
                    .bold()
                Spacer()
                // 建议加个完成/关闭按钮逻辑，保持一致性
            }
            .padding([.horizontal, .top], 30)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // 使用 ZStack 模拟信纸横线背景
                    ZStack(alignment: .topLeading) {
                        // ✨ 绘制横线装饰
                        VStack(spacing: 0) {
                            ForEach(0..<30, id: \.self) { _ in
                                VStack(spacing: 0) {
                                    Spacer().frame(height: fontSize + lineSpacing + 10) // 调整高度匹配词条高度
                                    Image("line")
                                        .resizable()
                                        .frame(height: 1.5)
                                        .opacity(0.6)
                                }
                            }
                        }

                        // 词条布局
                        FlowLayout(paragraph.words) { word in
                            let isSelected = selected.contains(word)

                            Text(word)
                                .appFont(AppFont.story()) // 建议使用统一字体
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    isSelected ?
                                    Color.yellow.opacity(0.6) :
                                    Color.black.opacity(0.05) // 未选中时给个浅底色
                                )
                                .cornerRadius(4)
                                .onTapGesture {
                                    if selected.contains(word) {
                                        selected.remove(word)
                                    } else {
                                        if selected.count < 5 {
                                            selected.insert(word)
                                        }
                                    }
                                }
                                .padding(.vertical, 5) // 增加词条垂直间距，对齐横线
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
            }
            
            // 底部操作区
            VStack {
                Button(action: {
                    onFinish(Array(selected))
                }) {
                    Text("确认选择 (\(selected.count)/5)")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selected.isEmpty ? Color.gray : Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selected.isEmpty)
                .padding(30)
            }
        }
        // ✨ 应用信纸背景色和圆角
        .background(themeColor.ignoresSafeArea())
        .cornerRadius(25)
        .shadow(radius: 10)
    }
}
