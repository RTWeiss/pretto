//
//  HomeScreenViewController.swift
//  Pretto
//
//  Created by Josiah Gaskin on 6/14/15.
//  Copyright (c) 2015 Pretto. All rights reserved.
//

import Foundation

class HomeScreenViewController : ZoomableCollectionViewController, UICollectionViewDataSource {
    
    var selectedEvent : Event?
    var liveEvents : [Event] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.headerReferenceSize = CGSizeMake(0, 44)
        flowLayout.footerReferenceSize = CGSizeMake(0, 44)
        allowsSelection = false
        refreshData()
    }
    
    func refreshData() {
        Event.getAllLiveEvents() { (events) -> Void in
            self.liveEvents = events
            
            /////// DUMMY DATA ////////////
            let ev1 = Event()
            ev1.name = "Sarah's Wedding"
            let alb1 = Album()
            for var i = 0; i < 60; i++ {
                alb1.addPhoto(ThumbnailPhoto())
            }
            ev1.albums = [alb1]
            self.liveEvents.append(ev1)
            
            let ev2 = Event()
            ev2.name = "Crazy Night Out"
            let alb2 = Album()
            for var i = 0; i < 43; i++ {
                alb2.addPhoto(ThumbnailPhoto())
            }
            ev2.albums = [alb2]
            self.liveEvents.append(ev2)
            
            ////// DUMMY DATA /////////////
            self.collectionView.reloadData()
        }
    }
}

// UICollectionViewDataSource Extension
extension HomeScreenViewController {
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! SelectableImageCell
        cell.backgroundColor = UIColor.blueColor()
        cell.updateCheckState()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(liveEvents[section].getAllPhotosInEvent(nil).count, 10)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return liveEvents.count
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let ev = liveEvents[indexPath.section]
        
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "sectionheader", forIndexPath: indexPath) as! EventHeader
            header.event = ev
            return header
        } else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "sectionfooter", forIndexPath: indexPath) as! EventFooter
            footer.event = ev
            return footer
        }
    }
    
    @IBAction func didTapToSelectEvent(sender: AnyObject) {
        let touchCoords = sender.locationInView(collectionView)
        let indexPath = pointToIndexPath(touchCoords, fuzzySize: 10)
        if indexPath != nil {
            self.selectedEvent = liveEvents[indexPath!.section]
            performSegueWithIdentifier("albumdetail", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "albumdetail" {
            let destination = segue.destinationViewController as! EventDetailViewController
            destination.event = self.selectedEvent
            self.selectedEvent = nil
        }
    }
}

class EventHeader : UICollectionReusableView {
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var event : Event? {
        didSet {
            label.text = event?.name ?? "Unknown"
        }
    }
    
    @IBAction func didTapPause(sender: AnyObject) {
        if pauseButton.currentTitle == "Pause" {
            pauseButton.setTitle("Continue", forState: UIControlState.Normal)
        } else {
            pauseButton.setTitle("Pause", forState: UIControlState.Normal)
        }
    }
}

class EventFooter : UICollectionReusableView {
    @IBOutlet weak var label: UILabel!
    
    var event : Event? {
        didSet {
            let count = event?.getAllPhotosInEvent(nil).count ?? 0
            label.text = count > 0 ? "+\(count) more" : ""
        }
    }
}
