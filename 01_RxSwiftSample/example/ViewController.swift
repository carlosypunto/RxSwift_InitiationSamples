//
//  ViewController.swift
//  01_Observables_and_Disposables
//
//  Created by carlos on 18/5/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet var textField1: UITextField!
    @IBOutlet var label1: UILabel!
    @IBOutlet var label2: UILabel!
    @IBOutlet var label3: UILabel!
    
    var instanceDisposable: Disposable? //

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // In RxSwift we have two main types, Observables (a Sequence) y Disposables (Observers)
        //   - Observables are objects that can change in value over time, triggering an Event when this happens
        //   - Disposables are responsible to do something when an Observable (to which it is subscribed) triggers an event
        
        // The Event type is an enum, which can be in three states .Next, .Error and .Completed
        // Both .Next as an error have an associated type, Box<T> in the case of .Next and ErrorType (is an NSError) in the case of .Error
        
        // textField1Observable is an Observable of type String
        // textField1Observable fire an Event.Next every time you add a character into textField1
        let textField1Observable /*: Observable<String> */ = textField1.rx_text()
        
        // subscribeNext returns a disposable (only for Events of .Next type) subscribed to the Observable
        let textField1Disposable /*: Disposable */ = textField1Observable
            >- subscribeNext { text in
                self.label1.text = text
            }
        
        // We can create as many disposables of a observable as you want
        // in this case, we assign it to an instance variable to access from the button's IBAction
        instanceDisposable = textField1Observable
            >- subscribeNext { text in
                self.label2.text = text
            }
        
        // We can to chain operations
        // in this we filter the observable .Next results
        textField1Observable
            >- filter { text in
                count(text) > 2
            }
            >- subscribeNext { text in
                self.label3.text = text
            }
        
    }

    @IBAction func completeInstanceObservable(sender: AnyObject) {
        // stop listening
        instanceDisposable?.dispose()
    }

}

