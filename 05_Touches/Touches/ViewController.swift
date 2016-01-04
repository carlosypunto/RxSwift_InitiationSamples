//
//  ViewController.swift
//  Touches
//
//  Created by carlos on 10/6/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var myView: UIView!
    @IBOutlet var pan: UIPanGestureRecognizer!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let beganLocations = pan.rx_event
            .filter { (gesture: UIGestureRecognizer) -> Bool in
                gesture.state == .Began
            }
            .map {
                $0.locationInView(self.view)
            }
        
        let endedLocations = pan.rx_event
            .filter { (gesture: UIGestureRecognizer) -> Bool in
                gesture.state == .Ended
                    || gesture.state == .Failed
                    || gesture.state == .Cancelled
            }
            .map {
                $0.locationInView(self.view)
            }
        
        let movedLocations = pan.rx_event
            .filter { (gesture: UIGestureRecognizer) -> Bool in
                gesture.state == .Changed
            }
            .map {
                $0.locationInView(self.view)
            }
        
        beganLocations
            .map { startLocation in

                return Observable.zip(movedLocations.startWith(startLocation), movedLocations) { (previous, next) in
                    return (next.x - previous.x, next.y - previous.y)
                    } .takeUntil(endedLocations)
            }
            .merge()
            .subscribeNext { [unowned self] difference in
                print(difference)
                var point = self.myView.center
                point.x += difference.0
                point.y += difference.1
                
                self.myView.center = point
            }
            .addDisposableTo(disposeBag)
        
    }


}