//
//  SceneDelegate.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 8/11/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import UIKit
import SwiftUI


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // Create a SwiftUI view
        let delegate = (UIApplication.shared.delegate as! AppDelegate)
        let contentView = ContentView(appState: delegate.appState, interactor: delegate.interactor)
        
        // Use a UIHostingController as root VC
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }
}
