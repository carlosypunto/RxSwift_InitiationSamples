//
//  Tweet.swift
//  TwitterInstant
//
//  Created by carlos on 18/4/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

struct Tweet {
  let status: String
  let profileImageUrl: String
  let username: String
  
  static func tweetWithStatus(status:[String: AnyObject]) -> Tweet {
    let tweetStatus = status["text"] as! String
    let user = status["user"] as! [String: AnyObject]
    let imageURL = user["profile_image_url"] as! String
    let username = user["screen_name"] as! String
    let tweet = Tweet(status: tweetStatus, profileImageUrl: imageURL, username: username)
    return tweet
  }
}
