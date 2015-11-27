//
//  Client.swift
//  SimpleWeather
//
//  Created by carlos on 12/6/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

private let API_KEY = "71dd46f4c058a1162652fb3e36df9623"

struct Client {
    
    func fetchCurrentConditionsForLocation(coordinate: CLLocationCoordinate2D) -> Observable<Condition> {
        let url = NSURL(string: "http://api.openweathermap.org/data/2.5/weather?APPID=\(API_KEY)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&units=metric")!
        print(url.absoluteString)
        return NSURLSession.sharedSession().rx_JSON(url)
            .map { json in
                return Condition.conditionFromObject(json)
            }
        
    }
    
    func fetchHourlyForecastForLocation(coordinate: CLLocationCoordinate2D) -> Observable<[Condition]> {
        let url = NSURL(string: "http://api.openweathermap.org/data/2.5/forecast?APPID=\(API_KEY)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&units=metric&cnt=12")!
        print(url.absoluteString)
        return NSURLSession.sharedSession().rx_JSON(url)
            .map { json in
                return Condition.conditionListFromObject(json)
            }
        
    }
    
    func fetchDailyForecastForLocation(coordinate: CLLocationCoordinate2D) -> Observable<[Condition]> {
        let url = NSURL(string: "http://api.openweathermap.org/data/2.5/forecast/daily?APPID=\(API_KEY)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&units=metric&cnt=7")!
        print(url.absoluteString)
        return NSURLSession.sharedSession().rx_JSON(url)
            .map { json in
                return Condition.conditionListFromDailyObject(json)
            }
        
    }
    
}