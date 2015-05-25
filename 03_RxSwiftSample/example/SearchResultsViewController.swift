//
//  SearchResultsViewController.swift
//  03_RxSwiftSample
//
//  Created by carlos on 20/5/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit

class SearchResultsViewController: UITableViewController {
    
    var tweets: [Tweet] = [Tweet]() {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TableViewCell
        let tweet = tweets[indexPath.row]
        cell.twitterStatusText.text = tweet.status
        cell.twitterUsernameText.text = tweet.username
        cell.twitterAvatarView.image = nil
        
        cell.putImage(tweet.profileImageUrl)
        
        return cell
    }

}
