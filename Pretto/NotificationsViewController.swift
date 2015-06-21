//
//  NotificationsViewController.swift
//  Pretto
//
//  Created by Josiah Gaskin on 6/20/15.
//  Copyright (c) 2015 Pretto. All rights reserved.
//

import Foundation

class NotificationsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var notifications : [Notification] = []
    var upcomingInvitations : [Invitation] = []
    var requests : [Request] = []
    
    var refreshControl : UIRefreshControl!
    var refreshCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 78
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        refreshData()
    }
    
    func refreshData() {
        refreshCount += 3
        Notification.getAll() {notifications in
            self.notifications = notifications
            if --self.refreshCount == 0 {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
        Invitation.getAllFutureEvents() {invites in
            self.upcomingInvitations = invites
            if --self.refreshCount == 0 {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
        Request.getAllPendingRequests() {requests in
            self.requests = requests
            if --self.refreshCount == 0 {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Invitations"
        case 1:
            return "Requests"
        case 2:
            return "Notifications"
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.upcomingInvitations.count
        case 1:
            return self.requests.count
        case 2:
            return self.notifications.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("invitecell", forIndexPath: indexPath) as! InviteCell
            cell.invite = self.upcomingInvitations[indexPath.row]
            return fixRowLine(cell)
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("request.cell", forIndexPath: indexPath) as! RequestCell
            cell.request = self.requests[indexPath.row]
            return fixRowLine(cell)
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("notificationcell", forIndexPath: indexPath) as! NotificationCell
            cell.notification = self.notifications[indexPath.row]
            return fixRowLine(cell)
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        tableView.beginUpdates()
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            var deleted : PFObject?
            switch indexPath.section {
            case 0:
                deleted = self.upcomingInvitations.removeAtIndex(indexPath.row)
            case 1:
                deleted = self.requests.removeAtIndex(indexPath.row)
            case 2:
                deleted = self.notifications.removeAtIndex(indexPath.row)
            default:
                deleted = nil
            }
            deleted?.deleteInBackground()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
        }
        tableView.endUpdates()
    }
    
    func fixRowLine(cell:UITableViewCell) -> UITableViewCell {
        if (cell.respondsToSelector(Selector("setPreservesSuperviewLayoutMargins:"))){
            cell.preservesSuperviewLayoutMargins = false
        }
        if (cell.respondsToSelector(Selector("setSeparatorInset:"))){
            cell.separatorInset = UIEdgeInsetsMake(0, 4, 0, 0)
        }
        if (cell.respondsToSelector(Selector("setLayoutMargins:"))){
            cell.layoutMargins = UIEdgeInsetsZero
        }
        return cell
    }
}

class InviteCell : UITableViewCell {
    @IBOutlet weak var title: UILabel!
    
    var invite : Invitation? {
        didSet {
            if let invite = self.invite {
                let host = User(innerUser: invite.from)
                let name = host.firstName ?? "Someone"
                title.text = "\(name) has invited you to their event \(invite.event.title)"
            } else {
                title.text = "Oops, an error occurred"
            }
        }
    }
}

class NotificationCell : UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    var notification : Notification? {
        didSet {
            if let n = notification {
                title.text = "\(n.title) - \(n.message)"
            } else {
                title.text = "Oops, an error occurred"
            }
        }
    }
}
