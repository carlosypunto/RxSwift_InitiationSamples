//
//  UIGestureRecognizer+Rx.swift
//  Touches
//
//  Created by carlos on 10/6/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import UIKit
import RxSwift

extension UIGestureRecognizer {
    public var rx_event: Observable<UIGestureRecognizer> {
        return AnonymousObservable { observer in
            MainScheduler.ensureExecutingOnScheduler()
            
            let observer = GestureTarget(self) {
                control in
                sendNext(observer, self)
            }
            
            return observer
        }
    }
}