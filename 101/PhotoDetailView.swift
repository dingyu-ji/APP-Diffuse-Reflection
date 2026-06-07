//
//  PhotoDetailView.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//

import SwiftUI

struct PhotoDetailView: View {

    @EnvironmentObject var photoStore: PhotoStore
    @Environment(\.presentationMode) var presentationMode // 用于关闭页面
    @State var photo: PhotoItem
    @State private var showNote = false
    @State private var noteText = ""
    @State private var flashOpacity: Double = 0 // 闪烁层

    var body: some View {
        ZStack {
            // 底层照片
            if let image = photoStore.loadImage(for: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }
            
//            Button(action: {
//                            presentationMode.wrappedValue.dismiss()
//                        }) {
//                            Image("backButton") // 自定义图片
//                                .resizable()
//                                .frame(width: 50, height: 50)
//                                .padding(8)
//                        }
//                        .position(x: 50, y: 50)
            
            Button(action: { showNote = true }) {
                            Image("noteBtn") // 你的自定义备注图片
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding(8)
                        }
                        .position(x: UIScreen.main.bounds.width - 50, y: 66)

            // 删除按钮，右下角浮动
           
                    Button(action: deletePhotoWithFlash) {
                        Image("deleteBtn") // 自定义图片
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding(8)
                    }
                    .position(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height - 80)
          
            // 全屏闪烁层
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            noteText = photo.note
        }
        
        // 备注弹窗
        .sheet(isPresented: $showNote) {
            NoteEditorView(noteText: $noteText) {
                photoStore.updateNote(for: photo, note: noteText)
                showNote = false
            }
            .presentationDetents([.fraction(0.6)])
            .presentationBackground(.clear)
            .presentationCornerRadius(0)
            .ignoresSafeArea()
        }
    }

    // MARK: - 删除照片 + 闪烁动画
    func deletePhotoWithFlash() {
        // 触发全屏闪烁
        withAnimation(.easeIn(duration: 0.1)) {
            flashOpacity = 0.8
        }

        // 闪烁结束后删除照片并返回相册
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                flashOpacity = 0
            }

            // 删除照片
            photoStore.delete(photo)

            // 返回相册
            presentationMode.wrappedValue.dismiss()
        }
    }
}
