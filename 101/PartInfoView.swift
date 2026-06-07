//
//  PartInfoView.swift
//  101
//
//  Created by 刘明 on 26/02/2026.
//

import SwiftUI

struct PartInfoView: View {
    @Binding var isPresented: Bool
    @State private var textHeight: CGFloat = 0
    let partName: String // 从 AR 传来的部件 ID
    
    // 视觉参数
    let themeColor = Color(red: 234/255, green: 232/255, blue: 224/255)
    let fontSize: CGFloat = 18
    let lineSpacing: CGFloat = 12
    
    var body: some View {
        // 从仓库中提取数据，如果没有则显示默认值
        let info = partRegistry[partName] ?? PartDescription(
            parentModel: "未知",
            title: "未找到部件",
            sections: [
                PartSection(imageName: "placeholder", text: "缺少数据")
            ]
        )
        
        VStack(spacing: 0) {
            // 顶部条：显示所属模型和关闭按钮
            HStack {
                Text("\(info.parentModel) > \(info.title)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .padding(10)
                        .background(Color.black.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    Text(info.title)
                        .appFont(AppFont.title())
                        .bold()
                        .padding(.horizontal)
                    
                    ForEach(info.sections.indices, id: \.self) { index in
                        let section = info.sections[index]
                        
                        VStack(alignment: .leading, spacing: 25) {
                            
                            ZStack {
                                Image(section.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                
                                Image("vidmask")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 220)
                                    .allowsHitTesting(false)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                
//                                VStack(spacing: 0) {
//                                    ForEach(0..<20, id: \.self) { _ in
//                                        VStack(spacing: 0) {
//                                            Spacer().frame(height: fontSize + lineSpacing - 1)
//                                            Image("line")
//                                                .resizable()
//                                                .frame(height: 1.5)
//                                        }
//                                    }
//                                }
                                
                                Text(section.text)
                                    .lineSpacing(lineSpacing)
                                    .padding(.bottom, 10)
                                    .background(
                                        VStack(spacing: 0) {
                                            ForEach(0..<20, id: \.self) { _ in
                                                VStack(spacing: 0) {
                                                    Spacer().frame(height: fontSize + lineSpacing - 1)
                                                    Image("line")
                                                        .resizable()
                                                        .frame(height: 1.5)
                                                }
                                            }
                                        }.clipped(),
                                        alignment: .top
                                        
                                    )
                            }
                            .clipped()

                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.5, alignment: .topLeading)
        .background(themeColor) // 使用你指定的背景色
        .cornerRadius(25)
        .shadow(radius: 10)
    }
}

