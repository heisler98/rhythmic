//
//  DrawerController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/21/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit

class DrawerController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet var gestureRecognizer : UIPanGestureRecognizer!
    var tracks : [Track]?
    var name: String?
    
    var drawerDismissClosure: (() -> Void)?
    var didChangeLayoutClosure: (() -> Void)?
    var panGestureTarget: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        label.text = name
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didChangeLayoutClosure?()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        drawerDismissClosure?()
    }

}

extension DrawerController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tracks = self.tracks else { return 0 }
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell", for: indexPath)
        guard let tracks = self.tracks else { return cell }
        cell.textLabel?.text = tracks[indexPath.row].title
        cell.backgroundView = nil
        cell.backgroundColor = nil
        cell.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension DrawerController : DrawerConfiguration {
    func topPositionY(for parentHeight: CGFloat) -> CGFloat {
        return 140
    }
    
    func middlePositionY(for parentHeight: CGFloat) -> CGFloat? {
        return nil
    }
    
    func bottomPositionY(for parentHeight: CGFloat) -> CGFloat {
        return parentHeight-100
    }
    
  
    func setPanGestureTarget(_ target: Any, action: Selector) {
        panGestureTarget = target
        gestureRecognizer.addTarget(target, action: action)
    }
    
    
}
