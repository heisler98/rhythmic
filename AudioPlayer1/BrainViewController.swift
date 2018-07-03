//
//  BrainViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 6/20/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation

class BrainViewController: UIViewController {

    var webView : WKWebView!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        guard let brainURL = URL(string: "https://www.brainaural.com/") else { return }
        let request = URLRequest(url: brainURL)
        webView.load(request)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
