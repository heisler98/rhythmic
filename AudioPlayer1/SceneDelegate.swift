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
    let appState = AppState()
    var interactor: Interactor {
        let interactor = Interactor(viewModel: appState.viewModel)
        appState.anyCancellable.append(contentsOf: [
                                        interactor.playbackPaused.assign(to: \.playbackPaused, on: appState),
                                        interactor.playingTrack.map { Optional<Track>($0) }.assign(to: \.playingTrack, on: appState)
        ])
        return interactor
    }
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // Create a SwiftUI view
        let contentView = ContentView(appState: appState, interactor: interactor)
        
        // Use a UIHostingController as root VC
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let global = DispatchQueue.global(qos: .userInitiated)
        global.async {
            
            for context in URLContexts {
                let url = context.url
                let destinationURL = DataHandler.documentsDirectory.appendingPathComponent("files/\(url.lastPathComponent)")
                do {
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    try FileManager.default.removeItem(at: url)
                } catch {
                    dLog(error)
                }
                _ = DataHandler.setPreferredFileProtection(on: destinationURL)
                self.appState.newTrack(at: destinationURL)
            }
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
