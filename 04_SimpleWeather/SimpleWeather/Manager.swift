//
//  Manager.swift
//  SimpleWeather
//
//  Created by carlos on 12/6/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

let LocationUpdateNotificationName = "LocationUpdateNotificationName"

class Manager: NSObject, CLLocationManagerDelegate {
    
    static let sharedManager = Manager()
    
    private let disposeBag = DisposeBag()
    
    private let locationManager = CLLocationManager()
    private var isFirstUpdate = true
    
    var data: Observable<(Condition, [Condition], [Condition])>
    
    private override init() {
        
        let client = Client()
        
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = NSQualityOfService.UserInitiated
        let backgroundWorkScheduler = OperationQueueScheduler(operationQueue: operationQueue)
        
        self.data = NSNotificationCenter.defaultCenter().rx_notification(LocationUpdateNotificationName, object: nil)
            >- map { notif in 
                (notif.object as! CLLocation).coordinate
            }
            >- observeOn(backgroundWorkScheduler)
            >- map { location in
                let updateCurrentConditions = client.fetchCurrentConditionsForLocation(location)
                let updateDailyForecast = client.fetchDailyForecastForLocation(location)
                let updateHourlyForecast = client.fetchHourlyForecastForLocation(location)
                
                return zip(updateCurrentConditions, updateDailyForecast, updateHourlyForecast) { conditions, daily, hourly in
                    return (conditions, daily, hourly)
                    }
                    >- observeOn(backgroundWorkScheduler)
            }
            >- switchLatest
            >- variable
        
        super.init()
        locationManager.delegate = self
    }
    
    func findCurrentLocation() {
        isFirstUpdate = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if isFirstUpdate {
            isFirstUpdate = false
            return
        }
        let location = locations.last as? CLLocation
        if let location = location {
            if location.horizontalAccuracy > 0 {
                NSNotificationCenter.defaultCenter().postNotificationName(LocationUpdateNotificationName, object: location)
                locationManager.stopUpdatingLocation()
            }
        }
    }
    
    
}