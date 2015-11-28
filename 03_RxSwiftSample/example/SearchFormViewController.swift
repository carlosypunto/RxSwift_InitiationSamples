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
    var noAccountOverlay: UILabel?
    
    var resultsViewController: SearchResultsViewController!
    
    var accountStore = ACAccountStore()
    var twitterAccountType: ACAccountType!
    
    let disposeBag = DisposeBag()
    var searchDisposeBag = DisposeBag()
    
    var accountChangedObservable: Observable<[ACAccount]>!
    
    var $ = Dependencies.sharedDependencies
        
    var requestAccess: Observable<TwitterAccountState>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestAccess = createTwitterAccountObservable()
            .shareReplay(1)
        
        resultsViewController = splitViewController?.viewControllers[1] as! SearchResultsViewController
        twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        requestAccess
            .map { twitterAccountState -> Observable<[Tweet]> in
                switch twitterAccountState {
                case .TwitterAccounts(let accounts):
                    if accounts.count > 0 {
                        return self.searchResultsForAccount(accounts[0])
                    } else {
                        return just([])
                    }
                default:
                    return just([])
                }
            }
            .switchLatest()
            .subscribeNext { [unowned self] tweets in
                self.resultsViewController.tweets = tweets
            }
            .addDisposableTo(disposeBag)
        
        searchText.rx_text
            // you can do map or just transform in subscribeNext
            .subscribeNext { [unowned self] text in
                let backgroundColor = self.isValidSearchText(text) ? UIColor.whiteColor() : UIColor.yellowColor()
                self.searchText.backgroundColor = backgroundColor
            }
            .addDisposableTo(disposeBag)
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
        return text.utf8.count > 2
    }
    
    // MARK: Custom observables
    
    private func getTwitterAccountsFromStore(store: ACAccountStore) -> [ACAccount] {
        let twitterType = store.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)!
        let accounts = store.accountsWithAccountType(twitterType)
        if accounts.count == 0 {
            return []
        } else {
            return accounts.map { $0 as! ACAccount }
        }
    }
    
    private func createTwitterAccountObservable() -> Observable<TwitterAccountState> {
        let observable1: Observable<TwitterAccountState> = create { observer in
            self.accountStore.requestAccessToAccountsWithType(self.twitterAccountType, options: nil) { success, error in
                if success {
                    observer.on(.Next(.TwitterAccounts(accounts: self.getTwitterAccountsFromStore(self.accountStore))))
                } else {
                    observer.on(.Next(.AccessDenied))
                }
            }
            return AnonymousDisposable {}
        }
        
        let observable2: Observable<TwitterAccountState> = NSNotificationCenter.defaultCenter().rx_notification(ACAccountStoreDidChangeNotification, object: nil) 
            .map { notif in
                let accountStore = notif.object as! ACAccountStore
                let accounts = self.getTwitterAccountsFromStore(accountStore)
                return .TwitterAccounts(accounts: accounts)
        }
        
        return sequenceOf(observable1, observable2).merge()
    }
    
    private func requestforTwitterSearchWithText(text: String) -> SLRequest {
        let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
        let params = ["q": text]
        return SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
    }
    
    private func twitterSearchAPICall(account: ACAccount, text: String) -> Observable<[String: AnyObject]> {

        print("create observable")
        
        let request = requestforTwitterSearchWithText(text)
        request.account = account
        
        let urlSession = NSURLSession.sharedSession()
        
        return urlSession.rx_JSON(request.preparedURLRequest())
            .observeOn(Dependencies.sharedDependencies.backgroundWorkScheduler)
            .map { json in
                guard let json = json as? [String: AnyObject] else {
                    throw exampleError("Casting to dictionary failed")
                }
                
                return json
            }
            .observeOn(Dependencies.sharedDependencies.mainScheduler)
    }
    
    // MARK: Create Search in Twitter Disposable
    
    func searchResultsForAccount(account: ACAccount) -> Observable<[Tweet]> {
        
        searchDisposeBag = DisposeBag()
        
        let distinctText: Observable<String> = searchText.rx_text
            .filter { (text: String) -> Bool in
                print(text)
                return self.isValidSearchText(text)
            }
            .distinctUntilChanged { (lhs: String, rhs: String) -> Bool in
                return lhs == rhs
            }
            
            .throttle(0.5, $.mainScheduler)
        return distinctText
            .map { text in
                return self.twitterSearchAPICall(account, text: text)
                      .catchError { error in
                        return just([String: AnyObject]())
                      }
            }
            .switchLatest()
            .observeOn($.mainScheduler)
            .map { dictionary in
                if let statuses = dictionary["statuses"] as? [[String: AnyObject]] {
                    let tweets = statuses.map {
                        return Tweet.tweetWithStatus($0)
                    }
                    
                    return tweets
                } else {
                    return []
                }
            }
            .observeOn(MainScheduler.sharedInstance)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let parentView = UIApplication.sharedApplication().keyWindow!.rootViewController!.view
        noAccountOverlay = UILabel(frame: parentView!.frame)
        noAccountOverlay!.text = "Please login to Twitter"
        noAccountOverlay!.backgroundColor = UIColor(white: 1, alpha: 0.9)
        noAccountOverlay?.textAlignment = .Center
        parentView?.addSubview(noAccountOverlay!)
        
        requestAccess
            .observeOn(MainScheduler.sharedInstance)
            .subscribeNext { [unowned self] access in
                print("subscribeNext \(access)")
                switch access {
                case .TwitterAccounts(let accounts):
                    print(accounts)
                    let hidden = accounts.count != 0
                    print("\(self.noAccountOverlay)\(hidden)")
                    self.noAccountOverlay?.hidden = hidden
                case .AccessDenied:
                    print("Access denied")
                    self.noAccountOverlay?.hidden = false
                    self.showAccessDeniedAlert()
                }
            }
            .addDisposableTo(disposeBag)
    }

}
