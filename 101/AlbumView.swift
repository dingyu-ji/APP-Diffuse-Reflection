//
//  AlbumView.swift
//  101
//
//  Created by 刘明 on 27/02/2026.
//

import SwiftUI

// MARK: - AlbumView
struct AlbumView: View {

    @EnvironmentObject var photoStore: PhotoStore
    @Environment(\.dismiss) var dismiss

    // 控制显示哪张照片
    @State private var selectedPhoto: PhotoItem? = nil

    var body: some View {
        ZStack {
            // 相册网格
            
            Image("albumBG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        
            VStack {

                Spacer()

                // ⭐⭐⭐ 相册窗口
                GeometryReader { geo in

                    let containerWidth = geo.size.width
                    let spacing: CGFloat = 12
                    let columns: CGFloat = 3
                    let horizontalPadding: CGFloat = 24

                    
                    let itemSize = (containerWidth - 2 * horizontalPadding - spacing * (columns - 1)) / columns

                    ScrollView {

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.fixed(itemSize), spacing: spacing),
                                count: Int(columns)
                            ),
                            spacing: spacing
                        ) {
                            ForEach(photoStore.photos) { item in
                                if let image = photoStore.loadImage(for: item) {

                                    Button {
                                        withAnimation(.easeInOut) {
                                            selectedPhoto = item
                                        }
                                    } label: {

                                        ZStack {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: itemSize,
                                                       height: itemSize)
                                                .clipped()

                                            Image("noteMask")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: itemSize * 1.1,
                                                       height: itemSize * 1.1)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(spacing)
                    }
                }
                .frame(width: 300, height: 700)   // ⭐ 相册窗口尺寸
                .clipped()                        // ⭐ 超出直接裁掉

                Spacer()
            }
            
            // PhotoDetailView 从底部滑上
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo)
                .environmentObject(photoStore)
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        
        .overlay(
            Button(action: {
                dismiss() // 返回上一个页面（拍照页）
            }) {
                Image("backButton") // 你自己的返回按钮图片
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding(8)
            }
            .padding(.leading, 25)
            .padding(.top, 30),
            alignment: .topLeading
        )
    }
}


