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

class ViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInFailureText: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var disposeBag = DisposeBag()
    var backgroundWorkScheduler: ImmediateSchedulerType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = NSQualityOfService.UserInitiated
        backgroundWorkScheduler = OperationQueueScheduler(operationQueue: operationQueue)

        /* map function transform a sequence of a type in another sequence of diferent type */
        let validUsernameSignal /* : Observable<Bool> */ = usernameTextField.rx_text
            // map Observable<String> to an Observable<Bool>
            .map { username in
                return username.characters.count > 3
            }

        let validPasswordSignal /* : Observable<Bool> */ = passwordTextField.rx_text
            // map Observable<String> to an Observable<Bool>
            .map { password in
                return password.characters.count > 3
            }
        
        validUsernameSignal
            // map Observable<Bool> to an Observable<UIColor>
            .map { isValid in
                isValid ? UIColor.clearColor() : UIColor.yellowColor()
            }
            .subscribeNext { [unowned self] color in
                self.usernameTextField.backgroundColor = color
            }
            .addDisposableTo(disposeBag)
        
        validPasswordSignal
            // map Observable<Bool> to an Observable<UIColor>
            .map { isValid in
                isValid ? UIColor.clearColor() : UIColor.yellowColor()
            }
            .subscribeNext { [unowned self] color in
                self.passwordTextField.backgroundColor = color
            }
            .addDisposableTo(disposeBag)
        
        // you can combine multiples observable
        let signUpActiveSignal /*: Observable<Bool> */ = Observable.combineLatest(validUsernameSignal, validPasswordSignal) { isValidUserName, isValidPassword in
            return isValidUserName && isValidPassword
        }
        
        // suscribing to an combined observable
        signUpActiveSignal
            .subscribeNext { [unowned self] valid in
                self.signInButton.enabled = valid
            }
            .addDisposableTo(disposeBag)
        // Note:
        // DisposeBag retains the disposable, otherwise it will attempt to retain a deallocated object (Test to run the a app commenting the line '.disposeBag.addDisposable')
        // The previous disposable we could have assigned to an instance variable, but add this to save DisposeBag instance variables in case you have to hold several disposables
        // Moreover, DisposeBag has a `dispose()` method, which dispose all observable added to it
        
        
        self.signInButton.enabled = false
        self.signInFailureText.hidden = true
        
        signInButton.rx_tap.asObservable()
            .doOn(onNext: { [unowned self] in self.activityIndicator.startAnimating() })
            // For every tap, we submit a request to our dummy async service 
            // to check if credentials are valid on the background thread
            .flatMap {
              DummyAsynchronousService()
                .login(self.usernameTextField.text!, password: self.passwordTextField.text!)
                .observeOn(self.backgroundWorkScheduler)
            }
            // We observe the result of the async service on the main thread
            .observeOn(MainScheduler.instance)
            // Upon a next event, we do the following:
            // 1. Stop the activity indicator
            // 2. Show sign in failure text if invalid
            // 3. Enable the sign in button
            // 4. If valid, perform segue and reset current controller.
            .subscribeNext { [unowned self] valid in
                self.activityIndicator.stopAnimating()
                self.signInFailureText.hidden = valid
                self.signInButton.enabled = true
                if valid {
                    self.performSegueWithIdentifier("goToOtherVC", sender: self)
                    self.usernameTextField.text = ""
                    self.passwordTextField.text = ""
                    self.usernameTextField.backgroundColor = UIColor.yellowColor()
                    self.passwordTextField.backgroundColor = UIColor.yellowColor()
                    self.signInButton.enabled = false
                }
            }
            .addDisposableTo(disposeBag)
    }
}


typealias ValidationObservable = Observable<(valid: Bool?, message: String?)>

class DummyAsynchronousService {
  // Dummy login method that checks the username and password and delays subscription
  // by two seconds.
  func login(userName: String, password: String) -> Observable<Bool> {
    let success = userName == "user" && password == "password"

    // Returns the value of success on a delayed timer of 2 seconds on the main thread
    return Observable.just(success).delaySubscription(2, scheduler: MainScheduler.instance)
  }
}
