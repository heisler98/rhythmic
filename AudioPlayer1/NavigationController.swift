//
//  NavigationController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/11/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self as UINavigationControllerDelegate
        // Do any additional setup after loading the view.
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let vc = viewController as? ViewController else { return }
        vc.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
