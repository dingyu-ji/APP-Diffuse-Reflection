//
//  NoteEditorView.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//


import SwiftUI

struct NoteEditorView: View {

    @Binding var noteText: String
    var onSave: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // 图片
            Image("noteBk")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .overlay(
                    // 文字和按钮在图片内部
                    GeometryReader { geo in
                        ZStack(alignment: .topTrailing) {
                            TextEditor(text: $noteText)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.black)
                                .frame(width: geo.size.width * 0.6, height: geo.size.height * 0.35)
                                // 按比例定位，随图片缩放自动改变大小和位置
                                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.35)

                            Button {
                                onSave()
                            }label: {
                            Image("saveBtn") // 你的图片名
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.12) // 控制大小（建议用比例）
                        }
                            .padding(.trailing, geo.size.width * 0.2) // 往左
                            .padding(.top, geo.size.height * 0.2)
                            
                            .position(x: geo.size.width * 0.9, y: geo.size.height * 0.05)
                        }
                    }
                )
        }
        .onAppear {
            isFocused = true
        }
    }
}
