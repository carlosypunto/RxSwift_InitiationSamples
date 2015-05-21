//
//  Dependencies.swift
//  WikipediaImageSearch
//
//  Created by carlos on 13/5/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import Foundation
import RxSwift

public class Dependencies {
	
	public static let sharedDependencies = Dependencies() // Singleton
	
	let backgroundWorkScheduler: ImmediateScheduler
	let mainScheduler: DispatchQueueScheduler
	
	private init() {
		let operationQueue = NSOperationQueue()
		operationQueue.maxConcurrentOperationCount = 2
		operationQueue.qualityOfService = NSQualityOfService.UserInitiated
		backgroundWorkScheduler = OperationQueueScheduler(operationQueue: operationQueue)
		
		mainScheduler = MainScheduler.sharedInstance
    }
	
}
