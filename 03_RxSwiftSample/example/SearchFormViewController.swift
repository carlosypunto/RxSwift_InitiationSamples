//
//  ViewController.swift
//  example
//
//  Created by carlos on 18/5/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Accounts
import Social


enum TwitterInstantError: Int {
    case AccessDenied, NoTwitterAccounts, InvalidResponse
}

let TwitterInstantDomain = "TwitterInstant"

class SearchFormViewController: UIViewController {
    
    @IBOutlet weak var searchText: UITextField!
    
    var resultsViewController: SearchResultsViewController!
    
    var accountStore = ACAccountStore()
    var twitterAccountType: ACAccountType!
    
    let disposeBag = DisposeBag()
    
    var $ = Dependencies.sharedDependencies

    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsViewController = splitViewController!.viewControllers[1] as! SearchResultsViewController
        
        twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        weak var weakSelf = self
        
        self.searchText.rx_text
            >- map { text in
                self.isValidSearchText(text) ? UIColor.whiteColor() : UIColor.yellowColor()
            }
            >- subscribeNext { [unowned self] color in
                self.searchText.backgroundColor = color
            }
            >- disposeBag.addDisposable
        
        
        let requestAccess /* : Observable<Void> */ = self.observableForRequestAccessToTwitter()
        requestAccess
            >- subscribeNext {
                println("Access granted")
            }
            >- disposeBag.addDisposable
        
        requestAccess
            >- subscribeError { error in
                println("An error ocured: \(error)")
            }
            >- disposeBag.addDisposable
        
        
        // workaround while `then` operator isn't ready
        requestAccess
            >- subscribeCompleted {
                
                let twitterDictionaryObservable /* : Observable<[String: AnyObject]?> */  = self.searchText.rx_text
                    >- filter { text in
                        self.isValidSearchText(text)
                    }
                    >- throttle(0.5, self.$.mainScheduler)
                    >- map { text in
                        self.observableForSearchWithText(text)
                    }
                    >- observeOn(self.$.backgroundWorkScheduler)
                    >- concat
                    >- observeOn(self.$.mainScheduler) // TODO: it'll work in next version
                
                twitterDictionaryObservable
                    >- subscribeNext { [unowned self] dictionary in
                        if let dictionary = dictionary, let statuses = dictionary["statuses"] as? [[String: AnyObject]] {
                            let tweets = statuses.map {
                                Tweet.tweetWithStatus($0)
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.resultsViewController.tweets = tweets
                            })
                        }
                    }
                    >- self.disposeBag.addDisposable
                
            }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func isValidSearchText(text: String) -> Bool {
        return count(text) > 2
    }
    
    private func observableForRequestAccessToTwitter() -> Observable<Void> {
        
        let error = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.AccessDenied.rawValue, userInfo: nil)
        
        return create { observer in
            let task = { [unowned self] () -> Void in
                self.accountStore.requestAccessToAccountsWithType(self.twitterAccountType, options: nil) { success, error in
                    if success {
                        observer.on(.Next(RxBox(Void())))
                    }
                    else {
                        observer.on(.Error(error))
                    }
                    observer.on(.Completed)
                }
            }
            task()
            return AnonymousDisposable {}
        }
        
    }
    
    private func requestforTwitterSearchWithText(text: String) -> SLRequest {
        let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
        let params = ["q": text]
        return SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
    }
    
    private func observableForSearchWithText(text: String) -> Observable<[String: AnyObject]?> {
        
        let noAccountsError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.AccessDenied.rawValue, userInfo: nil)
        let invalidResponseError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.AccessDenied.rawValue, userInfo: nil)
        
        return create { observer in
            let task = { [unowned self] () -> Void in
                
                let request = self.requestforTwitterSearchWithText(text)
                let twitterAccounts = self.accountStore.accountsWithAccountType(self.twitterAccountType)
                
                if twitterAccounts.count == 0 {
                    observer.on(.Error(noAccountsError))
                    observer.on(.Completed)
                }
                else {
                    request.account = twitterAccounts.last as! ACAccount
                    request.performRequestWithHandler { data, urlResponse, error in
                        if urlResponse.statusCode == 200 {
                            let timelineData = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as? [String: AnyObject]
                            observer.on(.Next(RxBox(timelineData)))
                        }
                        else {
                            observer.on(.Error(invalidResponseError))
                        }
                        observer.on(.Completed)
                    }
                }
            }
            task()
            return AnonymousDisposable {}
        }
    }

}

