//
//  Condition.swift
//  SimpleWeather
//
//  Created by carlos on 12/6/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Condition: CustomStringConvertible {
    
    let date: NSDate
    let humidity: Int
    let temperature: Float 
    let tempHigh: Float
    let tempLow: Float
    let locationName: String
    let sunrise: NSDate
    let sunset: NSDate
    let conditionDescription: String
    let condition: String
    let windBearing: Float
    let windSpeed: Float
    let icon: String
    
    var description: String {
        return locationName
    }
    
    static func imageName(name: String) -> String {
        switch name {
        case "01d": return "weather-clear"
        case "02d": return "weather-few"
        case "03d": return "weather-few"
        case "04d": return "weather-broken"
        case "09d": return "weather-shower"
        case "10d": return "weather-rain"
        case "11d": return "weather-tstorm"
        case "13d": return "weather-snow"
        case "50d": return "weather-mist"
        case "01n": return "weather-moon"
        case "02n": return "weather-few-night"
        case "03n": return "weather-few-night"
        case "04n": return "weather-broken"
        case "09n": return "weather-shower"
        case "10n": return "weather-rain-night"
        case "11n": return "weather-tstorm"
        case "13n": return "weather-snow"
        case "50n": return "weather-mist"
        default: return ""
        }
    }
    
    static func conditionFromObject(obj: AnyObject, daily: Bool = false) -> Condition {
        let json = JSON(obj)
        
        let date = NSDate(timeIntervalSince1970: NSTimeInterval(json["dt"].intValue))
        let humidity = json["main"]["humidity"].intValue
        let temperature = json["main"]["temp"].floatValue
        let tempHigh: Float
        let tempLow: Float
        if !daily {
            tempHigh = json["main"]["temp_max"].floatValue
            tempLow = json["main"]["temp_min"].floatValue
        }
        else {
            tempHigh = json["temp"]["max"].floatValue
            tempLow = json["temp"]["min"].floatValue
        }
        let locationName = json["name"].stringValue
        let sunrise = NSDate(timeIntervalSince1970: NSTimeInterval(json["sys"]["sunrise"].intValue))
        let sunset = NSDate(timeIntervalSince1970: NSTimeInterval(json["sys"]["sunset"].intValue))
        let conditionDescription = json["weather"].arrayValue[0]["description"].stringValue
        let condition = json["weather"].arrayValue[0]["main"].stringValue
        let windBearing = json["wind"]["deg"].floatValue
        let windSpeed = json["wind"]["speed"].floatValue
        let icon = Condition.imageName(json["weather"].arrayValue[0]["icon"].stringValue)
        
        return Condition(date: date, 
            humidity: humidity, 
            temperature: temperature, 
            tempHigh: tempHigh, 
            tempLow: tempLow, 
            locationName: locationName, 
            sunrise: sunrise, 
            sunset: sunset, 
            conditionDescription: conditionDescription, 
            condition: condition, 
            windBearing: windBearing, 
            windSpeed: windSpeed, 
            icon: icon)
    }
    
    static func conditionListFromObject(obj: AnyObject) -> [Condition] {
        let json = JSON(obj)
        return json["list"].arrayValue.map {
            return Condition.conditionFromObject($0.object, daily: false)
        }
        
    }
    
    static func conditionListFromDailyObject(obj: AnyObject) -> [Condition] {
        let json = JSON(obj)
        return json["list"].arrayValue.map {
            return Condition.conditionFromObject($0.object, daily: true)
        }
    }
    
}