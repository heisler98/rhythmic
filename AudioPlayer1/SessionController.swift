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
}

class SessionController: UITableViewController {

    var tracks : [Track]?
    var name : String?
    var delegate : SessionResponder?
    var sessionPath : IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        guard name != nil else { return }
        self.navigationItem.title = name!
   
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard tracks != nil else { return 0 }
        return tracks!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.TrackInSession.rawValue, for: indexPath)

        guard tracks != nil else { return cell }
        cell.textLabel?.text = tracks![indexPath.row].title

        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate?.trackRemoved(at: indexPath.row, from: sessionPath!.row)
            tracks?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }   
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        guard tracks != nil else { return }
        delegate?.trackMoved(from: fromIndexPath.row, to: to.row, in: sessionPath!.row)
        let toMove = tracks!.remove(at: fromIndexPath.row)
        tracks!.insert(toMove, at: to.row)
        tableView.moveRow(at: fromIndexPath, to: to)
    }
 

    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
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
