//
//  AppState.swift
//  101
//
//  Created by 刘明 on 23/02/2026.
//

import Foundation
import SwiftUI

enum AppScreen {
    case login
    case statusSelection
    case home
    case actionSelection
    case scan
    case photo
    case summary
    case personal
    case loadingConnect
}

class AppState: ObservableObject {
    
    @Published var currentScreen: AppScreen = .login
    // --- 新增，用于结算页 ---
    @Published var currentStory: String = ""          // 用户旅程生成的故事
    @Published var currentPhotos: [UIImage] = []      // 用户拍摄的照片
    @Published var currentModels: [ScannedModel] = [] // 用户查看过的模型
    @Published var navigationPath = NavigationPath()
}

