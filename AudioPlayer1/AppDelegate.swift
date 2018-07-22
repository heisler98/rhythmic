//
//  AppDelegate.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 11/3/16.
//  Copyright © 2016-2018 Hunter Eisler. All rights reserved.
//  Unauthorized copying of this file via any medium is strictly prohibited.
//  *Proprietary and confidential*

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        if (AudioManager.loadTracks() == nil) { //serialize PLIST, make [Tracks]
            
            let background = DispatchQueue.global(qos: .background)
            
            background.sync {
                
                if let plistURL = Bundle.main.url(forResource: "Tracks", withExtension: "plist") { //PLIST url
                
                    if let plistData = NSData(contentsOf: plistURL) { //PLIST data
                        let data = plistData as Data
                        var trackArr : Array<Dictionary<String, String>>?
                        var presets : TrackArray = []
                        do { //PLIST serialization to Array<Dictionary<String,String>> (TrackArray)
                            trackArr = try PropertyListSerialization.propertyList(from: data, options:.mutableContainers,   format:nil) as? Array<Dictionary<String, String>>
                        } catch {
                            print(error)
                        }
                    
                        guard let array = trackArr else { return }
                        
                        for dict in array {
                            let file = dict["title"]! + "." + dict["extension"]!
                            let aTrack = Track(title: dict["title"]!, period: Double(dict["period"]!)!, category: dict["category"]!, fileName: file, rhythm: .Bilateral, rate: .Normal)
                            presets.append(aTrack)
                            
                            let urlInBundle = Bundle.main.url(forResource: dict["title"]!, withExtension: dict["extension"]!)
                            do {
                                try FileManager.default.copyItem(at: urlInBundle!, to: aTrack.url)
                            } catch let error as NSError {
                                print("\(error)")
                            }
                        }
                        _ = AudioManager.saveTracks(presets)
                    }
                }
            }
        }
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Implement copying the music files
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent(url.lastPathComponent)
        
        do {
            
            try FileManager.default.copyItem(at: url, to: documentsDirectory)
        } catch {
            print("\(error)")
        }
        
        // need the audio file added to the list and its BPM analyzed
        // manager gets alerted of added track
        // manager should analyze BPM (if that's the route)
        // VC's TableView is updated on reentry
        
        guard let tabController = window?.rootViewController as? UITabBarController else { print("Cannot load root view controller."); return false }
        guard let navController = tabController.viewControllers!.first as? UINavigationController else { print("Cannot load navController in tab bar vcs"); return false}
        guard let vc = navController.childViewControllers.first as? ViewController else { print("Cannot load ViewController"); return false}
        
        return vc.newTrack(at: documentsDirectory.appendingPathComponent(url.pathComponents.last!))
        
    }
    
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



}

