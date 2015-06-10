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
    @IBOutlet weak var noAccountOverlay: UIView!
    
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
        
        let requestAccess /* : Observable<TwitterAccountState> */ = createTwitterAccountObservable() >- variable
        
        requestAccess
            >- subscribeNext { [unowned self] access in
                switch access {
                case .TwitterAccounts(let accounts):
                    let hidden = accounts.count != 0
                    println("\(self.noAccountOverlay)\(hidden)")
                    self.noAccountOverlay.hidden = hidden
                case .AccessDenied:
                    println("Access denied")
                    self.noAccountOverlay.hidden = true
                    self.showAccessDeniedAlert()
                }
            }
            >- disposeBag.addDisposable
        
        requestAccess
            >- map { [unowned self] twitterState in
                switch twitterState {
                case .TwitterAccounts(let accounts):
                    if accounts.count > 0 {
                        return self.searchResultsForAccount(accounts[0])
                    }
                    else {
                        return just([])
                    }
                case .AccessDenied:
                    return just([])
                }
            }
            >- switchLatest
            >- subscribeNext { [unowned self] tweets in
                self.resultsViewController.tweets = tweets
            }
            >- disposeBag.addDisposable
        
        self.searchText.rx_text
            // you can do map or just transform in subscribeNext
            >- subscribeNext { text in
                let backgroundColor = self.isValidSearchText(text) ? UIColor.whiteColor() : UIColor.yellowColor()
                self.searchText.backgroundColor = backgroundColor
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
    
    private func createTwitterAccountObservable() -> Observable<TwitterAccountState> {
        
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
        
        return merge(returnElements(observable1, observable2))
    }
    
    private func requestforTwitterSearchWithText(text: String) -> SLRequest {
        let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
        let params = ["q": text]
        return SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
    }
    
    private func twitterSearchAPICall(account: ACAccount, text: String) -> Observable<[String: AnyObject]> {
        
        println("create observable")
        
        let noAccountsError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.NoTwitterAccounts.rawValue, userInfo: nil)
        let invalidResponseError = NSError(domain: TwitterInstantDomain, code: TwitterInstantError.InvalidResponse.rawValue, userInfo: nil)
        
        let request = self.requestforTwitterSearchWithText(text)
        request.account = account
        
        let urlSession = NSURLSession.sharedSession()
        
        return urlSession.rx_JSON(request.preparedURLRequest())
            >- mapOrDie { url in
                return castOrFail(url)
            }
    }
    
    // MARK: Create Search in Twitter Disposable
    
    func searchResultsForAccount(account: ACAccount) -> Observable<[Tweet]> {
        
        self.searchDisposeBag.dispose() 
        
        let distinctText: Observable<String> = self.searchText.rx_text
            >- filter { (text: String) -> Bool in
                println(text)
                return self.isValidSearchText(text)
            }
            >- throttle(0.5, self.$.mainScheduler)
            >- distinctUntilChanged { (lhs: String, rhs: String) -> Bool in
                return lhs == rhs
            }
            
        return distinctText
            >- map { text in
                return self.twitterSearchAPICall(account, text: text)
                    >- catch([:])
            }
            >- switchLatest
            >- observeOn(self.$.backgroundWorkScheduler)
            >- observeOn(self.$.mainScheduler)
            >- map { dictionary in
                if  let statuses = dictionary["statuses"] as? [[String: AnyObject]] {
                    let tweets = statuses.map {
                        return Tweet.tweetWithStatus($0)
                    }
                    
                    return tweets
                }
                else {
                    return []
                }
            }
            >- observeOn(MainScheduler.sharedInstance)
        
    }

}

