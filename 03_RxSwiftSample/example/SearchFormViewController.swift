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

enum TwitterAccountState {
    case TwitterAccounts(accounts: [ACAccount])
    case AccessDenied
}

class SearchFormViewController: UIViewController {
    
    @IBOutlet weak var searchText: UITextField!
    
    var resultsViewController: SearchResultsViewController!
    
    var accountStore = ACAccountStore()
    var twitterAccountType: ACAccountType!
    
    let disposeBag = DisposeBag()
    let searchDisposeBag = DisposeBag()
    
    var accountChangedObservable: Observable<[ACAccount]>!
    
    var $ = Dependencies.sharedDependencies

    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsViewController = splitViewController!.viewControllers[1] as! SearchResultsViewController
        twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        let requestAccess /* : Observable<TwitterAccountState> */ = self.observableForRequestAccessToTwitter()
        
        requestAccess
            >- subscribeNext { access in
                switch access {
                case .TwitterAccounts(let accounts):
                    println("Access granted \(accounts)")
                    self.createSearchDisposable()
                case .AccessDenied:
                    println("Access denied")
                    self.searchDisposeBag.dispose()
                    self.showAccessDeniedAlert()
                }
                
                
            }
            >- disposeBag.addDisposable
        
        self.searchText.rx_text
            >- map { text in
                self.isValidSearchText(text) ? UIColor.whiteColor() : UIColor.yellowColor()
            }
            >- subscribeNext { [unowned self] color in
                self.searchText.backgroundColor = color
            }
            >- disposeBag.addDisposable
        
    }
    
    private func showAccessDeniedAlert() {
        self.searchText.text = ""
        self.searchText.resignFirstResponder()
        self.searchText.enabled = false
        let alert = UIAlertView(title: "Access Denied", message: "Please go to iPad settings app and activate twitter access for this app", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // MARK: Validation
    
    private func isValidSearchText(text: String) -> Bool {
        return count(text) > 2
    }
    
    // MARK: Custom observables
    
    private func getTwitterAccountsFromStore(store: ACAccountStore) -> [ACAccount] {
        let twitterType = store.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)!
        let accounts = store.accountsWithAccountType(twitterType).map { x in
            x as! ACAccount
        }
        return accounts
    }
    
    private func observableForRequestAccessToTwitter() -> Observable<TwitterAccountState> {
        
        let accessDeniedError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.AccessDenied.rawValue, userInfo: nil)
        
        let observable1: Observable<TwitterAccountState> = create { observer in
            self.accountStore.requestAccessToAccountsWithType(self.twitterAccountType, options: nil) { success, error in
                if success {
                    sendNext(observer, .TwitterAccounts(accounts: self.getTwitterAccountsFromStore(self.accountStore)))
                }
                else {
                    sendNext(observer, .AccessDenied)
                }
            }
            return AnonymousDisposable {}
        }
        
        let observable2: Observable<TwitterAccountState> = NSNotificationCenter.defaultCenter().rx_notification(ACAccountStoreDidChangeNotification, object: nil) 
            >- map { notif in
                let accountStore = notif.object as! ACAccountStore
                let accounts = self.getTwitterAccountsFromStore(accountStore)
                return .TwitterAccounts(accounts: accounts)
        }
        //            >- distinctUntilChanged
        
        return merge(returnElements(observable1, observable2))
        
    }
    
    private func requestforTwitterSearchWithText(text: String) -> SLRequest {
        let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
        let params = ["q": text]
        return SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
    }
    
    private func observableForSearchWithText(text: String) -> Observable<[String: AnyObject]?> {
        
        println("create observable")
        
        let noAccountsError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.NoTwitterAccounts.rawValue, userInfo: nil)
        let invalidResponseError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.InvalidResponse.rawValue, userInfo: nil)
        
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
    
    // MARK: Create Search in Twitter Disposable
    
    func createSearchDisposable() {
        
        self.searchDisposeBag.dispose() 
        
        self.searchText.rx_text
            >- filter { text in
                println(text)
                return self.isValidSearchText(text)
            }
            >- throttle(0.5, self.$.mainScheduler)
            >- distinctUntilChanged
            >- map { text in
                return self.observableForSearchWithText(text)
            }
            >- observeOn(self.$.backgroundWorkScheduler)
            >- concat
            >- observeOn(self.$.mainScheduler)
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
        //            >- self.searchDisposeBag.addDisposable // <<<<<<<<<< if decomment, don't work the app
        
    }

}

