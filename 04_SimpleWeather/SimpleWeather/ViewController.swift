//
//  ViewController.swift
//  SimpleWeather
//
//  Created by carlos on 11/6/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa
import SwiftyJSON

enum CellType {
    case Daily, Hourly
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var blurredImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    var screenHeight: CGFloat!
    
    let header = UIView()
    let temperatureLabel = UILabel()
    let hiloLabel = UILabel()
    let cityLabel = UILabel()
    let conditionsLabel = UILabel()
    let iconView = UIImageView()
    
    let hourlyFormatter = NSDateFormatter()
    let dailyFormatter = NSDateFormatter()
    
    let manager = Manager.sharedManager
    
    let disposeBag = DisposeBag()
    
    var dailyForecast = [Condition]()
    var hourlyForecast = [Condition]()
    
    var updating = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hourlyFormatter.dateFormat = "h a"
        dailyFormatter.dateFormat = "EEEE"
        
        screenHeight = UIScreen.mainScreen().bounds.size.height
        
        makeUI()
        
        manager.data
            .observeOn(MainScheduler.sharedInstance)
            .subscribeNext { (conditions, daily, hourly) in
                
                print(hourly)
                
                self.updating = false
                
                self.cityLabel.text = conditions.locationName
                self.conditionsLabel.text = conditions.condition
                self.temperatureLabel.text = "\(Int(conditions.temperature))°"
                self.iconView.image = UIImage(named: conditions.icon)
                self.hiloLabel.text = "\(Int(conditions.tempHigh))° / \(Int(conditions.tempLow))°"
                
                self.hourlyForecast = hourly
                self.dailyForecast = daily
                self.tableView.reloadData()
            }
            .addDisposableTo(disposeBag)
        
        manager.findCurrentLocation()
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func makeUI() {
        
        tableView.separatorColor = UIColor(white: 1, alpha: 0.2)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        
        let headerFrame = UIScreen.mainScreen().bounds
        let inset: CGFloat = 20
        
        let temperatureHeight: CGFloat = 110
        let hiloHeight: CGFloat = 40
        let iconHeight: CGFloat = 30
        
        let hiloFrame = CGRect(x: inset, 
            y: headerFrame.size.height - hiloHeight, 
            width: headerFrame.size.width - (2 * inset), 
            height: hiloHeight)
        
        let temperatureFrame = CGRect(x: inset, 
            y: headerFrame.size.height - (temperatureHeight + hiloHeight), 
            width: headerFrame.size.width - (2 * inset), 
            height: temperatureHeight)
        
        let iconFrame = CGRect(x: inset, 
            y: temperatureFrame.origin.y - iconHeight, 
            width: iconHeight, 
            height: iconHeight)
        
        let conditionsFrame = CGRect(x: iconFrame.origin.x + (iconHeight + 10), 
            y: temperatureFrame.origin.y - iconHeight, 
            width: self.view.bounds.size.width - (((2 * inset) + iconHeight) + 10), 
            height: iconHeight)
        
        header.frame = headerFrame
        header.backgroundColor = UIColor.clearColor()
        tableView.tableHeaderView = header
        
        temperatureLabel.frame = temperatureFrame
        temperatureLabel.backgroundColor = UIColor.clearColor()
        temperatureLabel.textColor = UIColor.whiteColor()
        temperatureLabel.text = "0°"
        temperatureLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 120)
        header.addSubview(temperatureLabel)
        
        hiloLabel.frame = hiloFrame
        hiloLabel.backgroundColor = UIColor.clearColor()
        hiloLabel.textColor = UIColor.whiteColor()
        hiloLabel.text = "0° / 0°"
        hiloLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 28)
        header.addSubview(hiloLabel)
        
        cityLabel.frame = CGRect(x: 0, y: 20, width: self.view.bounds.size.width, height: 30)
        cityLabel.backgroundColor = UIColor.clearColor()
        cityLabel.textColor = UIColor.whiteColor()
        cityLabel.text = "Loading..."
        cityLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        cityLabel.textAlignment = .Center;
        header.addSubview(cityLabel)
        
        conditionsLabel.frame = conditionsFrame
        conditionsLabel.backgroundColor = UIColor.clearColor()
        conditionsLabel.textColor = UIColor.whiteColor()
        conditionsLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        header.addSubview(conditionsLabel)
        
        iconView.frame = iconFrame
        iconView.backgroundColor = UIColor.clearColor()
        iconView.contentMode = .ScaleAspectFit
        header.addSubview(iconView)
    }
    
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return min(hourlyForecast.count, 6) + 1
        }
        return min(dailyForecast.count, 6) + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: cellIdentifier)
        }
        
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                configureHeaderCell(cell, title: "Hourly Forecast")
            }
            else {
                let condition = hourlyForecast[indexPath.row - 1]
                configureConditionCell(cell, condition: condition, cellType: .Hourly)
            }
        }
        else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                configureHeaderCell(cell, title: "Daily Forecast")
            }
            else {
                let condition = hourlyForecast[indexPath.row - 1]
                configureConditionCell(cell, condition: condition, cellType: .Daily)
            }
        }
        
        cell?.selectionStyle = .None
        cell?.backgroundColor = UIColor(white: 0, alpha: 0.2)
        cell?.textLabel?.textColor = UIColor.whiteColor()
        cell?.detailTextLabel?.textColor = UIColor.whiteColor()
        
        cell?.textLabel?.backgroundColor = UIColor.clearColor()
        cell?.detailTextLabel?.backgroundColor = UIColor.clearColor()
        
        return cell!
    }
    
    func configureHeaderCell(cell: UITableViewCell?, title: String) {
        cell?.textLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        cell?.textLabel?.text = title
        cell?.detailTextLabel?.text = ""
        cell?.imageView?.image = nil
        
        cell?.textLabel?.backgroundColor = UIColor.clearColor()
        cell?.detailTextLabel?.backgroundColor = UIColor.clearColor()
    }
    
    func configureConditionCell(cell: UITableViewCell?, condition: Condition, cellType: CellType) {
        cell?.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        cell?.detailTextLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        cell?.imageView?.image = UIImage(named: condition.icon)
        cell?.imageView?.contentMode = .ScaleAspectFit
        switch cellType {
        case .Daily:
            cell?.textLabel?.text = dailyFormatter.stringFromDate(condition.date)
            cell?.detailTextLabel?.text = "\(condition.tempHigh)° / \(condition.tempLow)°"
        case .Hourly:
            cell?.textLabel?.text = hourlyFormatter.stringFromDate(condition.date)
            cell?.detailTextLabel?.text = "\(condition.temperature)°"
        }
        
        cell?.textLabel?.backgroundColor = UIColor.clearColor()
        cell?.detailTextLabel?.backgroundColor = UIColor.clearColor()
    }
    
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = scrollView.bounds.size.height
        let position: CGFloat = max(scrollView.contentOffset.y, 0)
        let percent: CGFloat = min(position/height, 1)
        self.blurredImageView.alpha = percent
        
//        if !updating && scrollView.contentOffset.y < -50 {
//            updating = true
//            manager.findCurrentLocation()
//        }
    }
    
}



















