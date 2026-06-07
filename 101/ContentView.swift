//
//  ContentView.swift
//  101
//
//  Created by 刘明 on 22/02/2026.
//

import SwiftUI

struct ContentView: View {
    //@StateObject var arState = ARState()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var photoStore: PhotoStore
    
    @StateObject var journeyRecorder = JourneyRecorder()
    @StateObject var summaryLoader = SummaryLoader()
    @StateObject var galleryStore = GalleryStore()

    var body: some View {
        Group{
            switch appState.currentScreen {
                
            case .login:
                LoginView()   // 保留原来的 LoginPage
            case .statusSelection:
                StatusSelectionView()  // 使用你已有文件里的
            case .home:
                HomeView()    // 使用你已有文件里的
            case .actionSelection:
                ActionSelectionView()  // 使用你已有文件里的
                
            case .scan:
                ScanView().environmentObject(journeyRecorder)
            case .photo:
                CameraView()
                    .environmentObject(photoStore)
                
            case .summary:
                SummaryView()
                
            case .personal:
                PersonalView()
                
            case .loadingConnect:
                LoadingConnectView()
                    .environmentObject(journeyRecorder)
                    .environmentObject(summaryLoader)
            }
        }
        .environmentObject(journeyRecorder)
        .environmentObject(photoStore)
        .environmentObject(appState)
        .environmentObject(summaryLoader)
        .environmentObject(galleryStore)
        
        .appFont(AppFont.story())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .environmentObject(GalleryStore())
    }
}
