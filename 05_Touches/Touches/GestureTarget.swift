//
//  GestureTarget.swift
//  Touches
//
//  Created by Carlos García on 10/6/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
    
typealias GestureRecognizer = UIKit.UIGestureRecognizer


// This should be only used from `MainScheduler`
class GestureTarget: NSObject, Disposable {
    typealias Callback = (GestureRecognizer) -> Void
    
    let selector: Selector = "eventHandler:"
    
    let gestureRecognizer: GestureRecognizer
    var callback: Callback?
    
    init(_ gestureRecognizer: GestureRecognizer, callback: Callback) {
        self.gestureRecognizer = gestureRecognizer
        self.callback = callback
        
        super.init()
        
        gestureRecognizer.addTarget(self, action: selector)
        
        let method = self.methodForSelector(selector)
        if method == nil {
            fatalError("Can't find method")
        }
    }
    
    func eventHandler(sender: GestureRecognizer!) {
        if let callback = self.callback {
            callback(self.gestureRecognizer)
        }
    }
    
    func dispose() {
        MainScheduler.ensureExecutingOnScheduler()
        
        self.gestureRecognizer.removeTarget(self, action: self.selector)
        self.callback = nil
    }
    
    deinit {
        dispose()
    }
}

