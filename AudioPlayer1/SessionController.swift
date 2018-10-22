//
//  SessionController.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/16/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

import UIKit

///A protocol to conform to track editing in a Session.
protocol SessionResponder {
    /**
     Indicates a Track was removed from a specified Session.
     - parameters:
     
        - index: The index of a Track.
        - sessionIndex: The index of the Session.
 */
    func trackRemoved(at index: Index, from sessionIndex: Index)
    /**
     Indicates a Track was moved from one position to another inside a Session.
     - parameters:
     
        - oldIndex: The former index of the Track.
        - newIndex: The new index of the Track.
        - sessionIndex: The index of the Session.
 */
    func trackMoved(from oldIndex: Index, to newIndex: Index, in sessionIndex: Index)
    /**
     Indicates a Track was added to a Session.
     - parameters:
     
        - track: The Track to append.
        - sessionIndex: The index of the Session.
 */
    func addedTrack(_ track: Track, to sessionIndex: Index)
    /**
     Indicates the rhythm of a Track was changed.
     - parameters:
     
        - to: The new rhythm.
        - trackIndex: The index of the Track in the Session.
        - sessionIndex: The index of the Session.
 */
    func rhythmChanged(_ to: Rhythmic, at trackIndex: Index, in sessionIndex: Index)
    /**
     Indicates the rate of a Track was changed.
     - parameters:
     
        - to: The new rate.
        - trackIndex: The index of the Track in the Session.
        - sessionIndex: The index of the Session.
 */
    func rateChanged(_ to: PanRate, at trackIndex: Index, in sessionIndex: Index)
}

class SessionController: UITableViewController {

    var tracks : [Track]?
    var name : String?
    var delegate : SessionResponder?
    var sessionPath : IndexPath?
    ///The master collection of available Tracks.
    var masterCollection : [Track]?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.separatorColor = UIColor.swatch
        guard name != nil else { return }
        self.navigationItem.title = name!
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.isEditing == true { return 2 }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            guard tracks != nil else { return 0 }
            return tracks!.count
        }
        guard masterCollection != nil else { return 0 }
        return masterCollection!.count
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        
        if editing == true {
            tableView.insertSections(IndexSet(integer: 1), with: .bottom)
        } else {
            if tableView.numberOfSections == 2 {
                tableView.deleteSections(IndexSet(integer: 1), with: .bottom)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.TrackInSession.rawValue, for: indexPath)
        if indexPath.section == 0 {
            guard tracks != nil else { return cell }
            cell.textLabel?.text = tracks![indexPath.row].title
            cell.detailTextLabel?.text = detailText(forRow: indexPath)
            return cell
        }
        
        guard masterCollection != nil else { return cell }
        cell.textLabel?.text = masterCollection![indexPath.row].title
        cell.detailTextLabel?.text = ""
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        //if !tableView.isEditing { return .none }
        if indexPath.section == 0 { return UITableViewCell.EditingStyle.delete }
        return UITableViewCell.EditingStyle.insert
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        if fromIndexPath.section == 0 && to.section == 0 {
            guard tracks != nil else { return }
            delegate?.trackMoved(from: fromIndexPath.row, to: to.row, in: sessionPath!.row)
            let toMove = tracks!.remove(at: fromIndexPath.row)
            tracks!.insert(toMove, at: to.row)
            
        }
    }
 

    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        guard indexPath.section == 0 else { return false }
        return true
    }
 
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "In \(name!)" }
        return "Available"
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        let descriptor = UIFontDescriptor(name: UIFont.ProjectFonts.Regular.rawValue, size: 17)
        let font = UIFont(descriptor: descriptor, size: 17)
        headerView.textLabel?.font = font
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        
    }
    
    private func detailText(forRow indexPath: IndexPath) -> String {
        guard tracks != nil else { return "" }
        let rhythm = tracks![indexPath.row].rhythm.descriptor()
        let rate = tracks![indexPath.row].rate.descriptor()
        let amendedPeriod = tracks![indexPath.row].period.toPanRate(tracks![indexPath.row].rate)
        let periodString = String(format: "%.3f", amendedPeriod)
        
        return "\(rhythm) : \(rate) : \(periodString)"
        
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

extension SessionController {
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
    
    private func change(forRow indexPath: IndexPath, rhythm: Rhythmic?, rate: PanRate?) {
        guard let newRhythm = rhythm else {
            let newRate = rate!
            delegate?.rateChanged(newRate, at: indexPath.row, in: sessionPath!.row)
            tracks![indexPath.row].rate = newRate
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
