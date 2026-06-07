//
//  ActionSelectionView.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//

import SwiftUI

struct ActionSelectionView: View {

    @EnvironmentObject var appState: AppState
    @StateObject var angleTracker = AngleTracker()
    @State private var allowAutoBack = false

    var body: some View {

        ZStack {

            // ✅ 页面底色
            Color(hex: "#eae8df")
                .ignoresSafeArea()

            VStack(spacing: 30) {

                // ✅ 拍照按钮（图片按钮）
                Button {
                    allowAutoBack = false
                    appState.currentScreen = .photo
                } label: {
                    Image("photo_btn")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 190)
                }

                // ✅ 扫描按钮（图片按钮）
                Button {
                    allowAutoBack = false
                    appState.currentScreen = .scan
                } label: {
                    Image("scan_btn")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 190)
                }

            }
        }
        .onAppear{
            angleTracker.startTracking()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                allowAutoBack = true
            }
        }
        .onDisappear{
            angleTracker.stopTracking()
        }
        .onChange(of: angleTracker.currentAngle) { _, newAngle in
            
            guard allowAutoBack else {return}
            
            if newAngle < 60 || newAngle > 95 {
                appState.currentScreen = .home
            }
        }
    }
}
struct ActionSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActionSelectionView(angleTracker: AngleTracker())
            .environmentObject(AppState())
    }
}
