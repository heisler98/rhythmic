//
//  NavigationController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/11/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController, UINavigationControllerDelegate {
/*
    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
*/
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self as UINavigationControllerDelegate
        
        //extendedLayoutIncludesOpaqueBars = true
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let vc = viewController as? ViewController else { return }
        vc.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
 /*
    private func updateBarTintColor() {
        if #available(iOS 13.0, *) {
            self.navigationBar.barTintColor = UITraitCollection.current.userInterfaceStyle == .dark ? .black : .white
        }
    }
    
    override init(rootViewController: UIViewController) {
         super.init(rootViewController: rootViewController)
         self.updateBarTintColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         self.updateBarTintColor()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         super.traitCollectionDidChange(previousTraitCollection)
         self.updateBarTintColor()
    }
*/
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
