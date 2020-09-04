//
//  AppDelegate.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016-2018 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { dLog("Could not find user's document directory."); return true}
        if !FileManager.default.fileExists(atPath: docDir.appendingPathComponent("files", isDirectory: true).path) {
            try? FileManager.default.createDirectory(at: docDir.appendingPathComponent("files", isDirectory: true), withIntermediateDirectories: false, attributes: nil)
        }
        copyPreload()
        return true
    }

//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//            let destinationURL = paths[0].appendingPathComponent("files/\(url.lastPathComponent)")
//
//            do {
//                try FileManager.default.copyItem(at: url, to: destinationURL)
//                try FileManager.default.removeItem(at: url)
//            } catch {
//                dLog(error)
//            }
//            _ = DataHandler.setPreferredFileProtection(on: destinationURL)
//            self.appState.newTrack(at: destinationURL)
//        }
//
//        return true
//    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    private func copyPreload() {
        let handler = DataHandler()
        let destinationURL = DataHandler.documentsDirectory.appendingPathComponent("files")
        handler.copyAsset(fromBundle: Bundle.main.url(forResource: "Let's Hurt Tonight", withExtension: "mp3")!, toUserDomain: destinationURL)
        handler.copyAsset(fromBundle: Bundle.main.url(forResource: "Better", withExtension: "mp3")!, toUserDomain: destinationURL)
        handler.copyAsset(fromBundle: Bundle.main.url(forResource: "Born", withExtension: "mp3")!, toUserDomain: destinationURL)
        handler.copyAsset(fromBundle: Bundle.main.url(forResource: "If I Lose Myself", withExtension: "mp3")!, toUserDomain: destinationURL)
        handler.copyAsset(fromBundle: Bundle.main.url(forResource: "Human", withExtension: "mp3")!, toUserDomain: destinationURL)
    }
}
