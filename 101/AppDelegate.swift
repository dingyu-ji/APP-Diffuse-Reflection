//
//  AppDelegate.swift
//  101
//
//  Created by 刘明 on 22/02/2026.
//

//
//  AppDelegate.swift
//  101
//
//  Created by 刘明 on 22/02/2026.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appState = AppState()   // 全局唯一 AppState
    var photoStore = PhotoStore()
    var bleManager = BLEManager()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let contentView = ContentView()
            .environmentObject(appState) // 注入环境对象
            .environmentObject(photoStore)
            .environmentObject(JourneyRecorder())
            .environmentObject(bleManager)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

