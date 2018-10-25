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
    var sessionPath: IndexPath?
    var masterCollection: [Track]?
    weak var delegate : SessionResponder?
    
    var drawerDismissClosure: (() -> Void)?
    var didChangeLayoutClosure: (() -> Void)?
    var panGestureTarget: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        gestureRecognizer.delegate = self as UIGestureRecognizerDelegate
        tableView.separatorColor = UIColor.swatch
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        label.text = name
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didChangeLayoutClosure?()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        
        if editing == true {
            tableView.insertSections(IndexSet(integer: 1), with: .bottom)
            UIView.animate(withDuration: 0.35) {
                self.didChangeLayoutClosure?()
            }
        } else {
            if tableView.numberOfSections == 2 {
                tableView.deleteSections(IndexSet(integer: 1), with: .bottom)
                UIView.animate(withDuration: 0.35) {
                    self.didChangeLayoutClosure?()
                }
            }
        }
        
    }
    
    @IBAction func dismiss(_ sender: Any) {
        drawerDismissClosure?()
    }
    
    @IBAction func edit(_ sender: UIButton) {
        if !isEditing {
            setEditing(true, animated: true)
            sender.setTitle("Done", for: .normal)
        } else {
            setEditing(false, animated: true)
            sender.setTitle("Edit", for: .normal)
        }
    }
    
    fileprivate func detailText(forRow indexPath: IndexPath) -> String {
        guard tracks != nil else { return "" }
        let rhythm = tracks![indexPath.row].rhythm.descriptor()
        let rate = tracks![indexPath.row].rate.descriptor()
        let amendedPeriod = tracks![indexPath.row].period.toPanRate(tracks![indexPath.row].rate)
        let periodString = String(format: "%.3f", amendedPeriod)
        
        return "\(rhythm) : \(rate) : \(periodString)"
    }
    
    fileprivate func change(forRow indexPath: IndexPath, rhythm: Rhythmic?, rate: PanRate?) {
        guard let newRhythm = rhythm else {
            delegate?.rateChanged(rate!, at: indexPath.row, in: sessionPath!.row)
            tracks![indexPath.row].rate = rate!
            let cell = self.tableView.cellForRow(at: indexPath)
            cell?.detailTextLabel?.text = detailText(forRow: indexPath)
            return
        }
        
        delegate?.rhythmChanged(newRhythm, at: indexPath.row, in: sessionPath!.row)
        tracks![indexPath.row].rhythm = newRhythm
        let cell = self.tableView.cellForRow(at: indexPath)
        cell?.detailTextLabel?.text = detailText(forRow: indexPath)
    }

}

extension DrawerController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isEditing == true { return 2 }
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            guard let tracks = self.tracks else { return 0 }
            return tracks.count
        }
        guard masterCollection != nil else { return 0 }
        return masterCollection!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.TrackInSession.rawValue, for: indexPath)
        cell.backgroundView = nil
        cell.backgroundColor = nil
        cell.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        
        if indexPath.section == 0 {
            guard let tracks = self.tracks else { return cell }
            cell.textLabel?.text = tracks[indexPath.row].title
            cell.detailTextLabel?.text = detailText(forRow: indexPath)
            return cell
        }
        
        guard masterCollection != nil else { return cell }
        cell.textLabel?.text = masterCollection![indexPath.row].title
        cell.detailTextLabel?.text = ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate?.trackRemoved(at: indexPath.row, from: sessionPath!.row)
            tracks?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        if editingStyle == .insert {
            guard tracks != nil && masterCollection != nil else { return }
            let movingTrack = masterCollection![indexPath.row]
            tracks!.append(movingTrack)
            delegate?.addedTrack(movingTrack, to: sessionPath!.row)
            let newPath = IndexPath(row: tracks!.endIndex-1, section: 0)
            tableView.insertRows(at: [newPath], with: .bottom)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 { return UITableViewCell.EditingStyle.delete }
        return UITableViewCell.EditingStyle.insert
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section == 0 && destinationIndexPath.section == 0 {
            guard tracks != nil else { return }
            delegate?.trackMoved(from: sourceIndexPath.row, to: destinationIndexPath.row, in: sessionPath!.row)
            tracks!.moveElement(at: sourceIndexPath.row, to: destinationIndexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 else { return false }
        return true
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section == 0 {
            return proposedDestinationIndexPath
        } else {
            return sourceIndexPath
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 0 else { return "Available" }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        let descriptor = UIFontDescriptor(name: UIFont.ProjectFonts.Regular.rawValue, size: 17)
        let font = UIFont(descriptor: descriptor, size: 17)
        headerView.textLabel?.font = font
        headerView.backgroundView?.backgroundColor = UIColor.swatch.withAlphaComponent(0.5)
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) { }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 { return nil }
        let half = UIContextualAction(style: .normal, title: "0.5x", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: nil, rate: .Half)
            completionHandler(true)
        })
        half.backgroundColor = UIColor.red
        
        let normal = UIContextualAction(style: .normal, title: "1x", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: nil, rate: .Normal)
            completionHandler(true)
        })
        normal.backgroundColor = UIColor.gray
        
        let double = UIContextualAction(style: .normal, title: "2x", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: nil, rate: .Double)
            completionHandler(true)
        })
        double.backgroundColor = UIColor.blue
        
        let quad = UIContextualAction(style: .normal, title: "4x", handler: { action, view, completionHandler in
            self.change(forRow: indexPath, rhythm: nil, rate: .Quad)
            completionHandler(true)
        })
        quad.backgroundColor = UIColor.purple
        
        let config = UISwipeActionsConfiguration(actions: [half, normal, double, quad])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 { return nil }
        guard let sessionPath = self.sessionPath else { return nil }
        guard let delegate = self.delegate else { return nil }
        let bilateral = UIContextualAction(style: .normal, title: "Bilateral", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: .Bilateral, rate: nil)
            completionHandler(true)
        })
        bilateral.backgroundColor = UIColor.green
        
        let crosspan = UIContextualAction(style: .normal, title: "Crosspan", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: .Crosspan, rate: nil)
            completionHandler(true)
        })
        crosspan.backgroundColor = UIColor.purple
        
        let synthesis = UIContextualAction(style: .normal, title: "Synthesis", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: .Synthesis, rate: nil)
            completionHandler(true)
        })
        synthesis.backgroundColor = UIColor.blue
        
        let stitch = UIContextualAction(style: .normal, title: "Swave", handler: { _, _, completionHandler in
            self.change(forRow: indexPath, rhythm: .Stitch, rate: nil)
            completionHandler(true)
        })
        stitch.backgroundColor = UIColor.gray
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            guard self.tracks != nil else { completionHandler(false); return }
            self.tracks!.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            delegate.trackRemoved(at: indexPath.row, from: sessionPath.row)
            completionHandler(true)
        }
        
        let config = UISwipeActionsConfiguration(actions: [bilateral, synthesis, crosspan, stitch, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

extension DrawerController : DrawerConfiguration {
    func topPositionY(for parentHeight: CGFloat) -> CGFloat {
        guard isViewLoaded == true else { return 0 }
        var contentHeight = tableView.rect(forSection: 0).height
        if tableView.numberOfSections == 2 { contentHeight += tableView.rect(forSection: 1).height }
        guard parentHeight-(contentHeight+150) > 170 else {
            return 170
        }
        return parentHeight - (contentHeight + 150)
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

extension DrawerController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return true }
        if view.isDescendant(of: tableView) {
            return false
        }
        return true
    }
}

protocol QueueUpdater: AnyObject {
    /**
     Intercepts the result of the queue being updated.
     
     This is called when a `Queue` is mutated.
 */
    func notify()
}



class TrackDrawerController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var gestureRecognizer: UIPanGestureRecognizer!
    var viewModel : ViewModel?
    var queue: Queue? { return viewModel?.queue }
    var panGestureTarget: Any?
    
    var drawerDismissClosure: (() -> Void)?
    var didChangeLayoutClosure: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.queue.delegate = self as QueueUpdater
        textField.textColor = UIColor.swatch
        textField.delegate = self as UITextFieldDelegate
        
        let descriptor = UIFontDescriptor(name: UIFont.ProjectFonts.Regular.rawValue, size: 38)
        textField.font = UIFont(descriptor: descriptor, size: 38)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didChangeLayoutClosure?()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        drawerDismissClosure?()
    }
    @IBAction func save(_ sender: Any) {
        guard let viewModel = self.viewModel else { return }
        guard let text = textField.text else { return }
        guard viewModel.canBuildSession == true else { return }
        viewModel.buildSession(name: text)
        drawerDismissClosure?()
    }
}

extension TrackDrawerController : QueueUpdater {
    func notify() {
        //notification that queue has been updated
        tableView.reloadData()
    }
}

extension TrackDrawerController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel!.queue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell")
        //Setup cell
        
        
        guard viewModel != nil else { return cell! }
        cell?.textLabel?.text = viewModel!.tracks[queue![indexPath.row]].title
        cell?.detailTextLabel?.text = viewModel!.detailString(for: queue![indexPath.row])
        return cell!
    }
}

extension TrackDrawerController : DrawerConfiguration {
    func topPositionY(for parentHeight: CGFloat) -> CGFloat {
        guard isViewLoaded == true else { return 0 }
        let contentHeight = tableView.rect(forSection: 0).height
        guard parentHeight-(contentHeight+150) > 170 else {
            return 170
        }
        return parentHeight - (contentHeight + 150)
    }
    
    func middlePositionY(for parentHeight: CGFloat) -> CGFloat? {
        return nil
    }
    
    func bottomPositionY(for parentHeight: CGFloat) -> CGFloat {
        return 140
    }
    
    
    func setPanGestureTarget(_ target: Any, action: Selector) {
        panGestureTarget = target
        gestureRecognizer.addTarget(target, action: action)
    }
}

extension TrackDrawerController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
