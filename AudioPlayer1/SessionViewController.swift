//
//  SessionViewController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 5/15/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit

protocol SessionDelegate {
    func getPeriod() -> Double
    func getRate() -> PanRate
}


class SessionViewController: UIViewController, REMDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var toolbar : UIToolbar!
    
    @IBOutlet weak var imageViewLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingMargin: NSLayoutConstraint!
    
    var period : Double?
    var delegate : SessionDelegate?
    var viewAnimator : UIViewPropertyAnimator?
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    // MARK: - View controls
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = delegate else { return }
        let val = self.delegate!.getPeriod()
        
        if val != 0 { self.period = val } else {
            //do nothing
        }
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.hidesBarsOnTap = true
        if self.period != nil {
            beginAnimating()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.hidesBarsOnTap = false
        stopAnimating()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        UIView.setAnimationsEnabled(false)
        
        coordinator.notifyWhenInteractionChanges { (context) in
            UIView.setAnimationsEnabled(true)
        }
    }
    */
    
    // MARK: - Image View controls
    
    func beginAnimating() {
        guard let _ = self.period else { return }
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        viewAnimator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: self.period!, delay: 0, options: [.curveLinear, .repeat, .autoreverse], animations: {
            
            switch self.imageViewLeadingMargin.isActive {
            
            case false:
                self.imageViewTrailingMargin.isActive = false
                self.imageViewLeadingMargin.isActive = true
                break
                
            case true:
                self.imageViewLeadingMargin.isActive = false
                self.imageViewTrailingMargin.isActive = true
                break
            }
            UIView.setAnimationRepeatCount(Float.greatestFiniteMagnitude)
            UIView.setAnimationRepeatAutoreverses(true)
            
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    func stopAnimating() {
        guard let _ = viewAnimator else { return }
        viewAnimator!.stopAnimation(false)
        viewAnimator!.finishAnimation(at: .start)
    }
    
    @IBAction func restart(_ sender : UIBarButtonItem) {
        stopAnimating()
        beginAnimating()
    }
    
    // MARK: - REM delegation
    
    func periodChanged(to new: Double) {
        
        stopAnimating()
        self.period = new
        beginAnimating()
    }
    
    func playbackStopped() {
        
        self.period = nil
        stopAnimating()
    }

}
