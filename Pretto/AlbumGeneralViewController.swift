//
//  AlbumGeneralViewController.swift
//  Pretto
//
//  Created by Francisco de la Pena on 6/18/15.
//  Copyright (c) 2015 Pretto. All rights reserved.
//

import UIKit

class AlbumGeneralViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    var refreshControl : UIRefreshControl!
    var liveEvents : [Event] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.prettoWhite()
        searchBar.backgroundColor = UIColor.prettoWhite()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshData() {
        Event.getAllLiveEvents() { (events) -> Void in
            self.liveEvents = events
            for event in self.liveEvents {
                event.getInvitation().updateFromCameraRoll()
            }
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: UITableViewDelegate

extension AlbumGeneralViewController : UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var calendarHeight = CGFloat(40.0)
        var calendarTopAndBottom = CGFloat(14.0)
        var cellWidth = tableView.frame.width
        var imageHeight = 0.24 * cellWidth
        var verticalSeparator = CGFloat(5.0)
        var cellHeight = calendarHeight + (2 * imageHeight) + (2 * verticalSeparator) + calendarTopAndBottom
        return cellHeight
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

// MARK: UITableViewDataSource

extension AlbumGeneralViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return liveEvents.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AlbumGeneralViewCell", forIndexPath: indexPath) as! AlbumGeneralViewCell
        cell.event = liveEvents[indexPath.row]
        return cell
    }
}
