//
//  TableViewCell.swift
//  TwitterInstant
//
//  Created by carlos on 18/4/15.
//  Copyright (c) 2015 Carlos García. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var twitterAvatarView: UIImageView!
    @IBOutlet weak var twitterStatusText: UILabel!
    @IBOutlet weak var twitterUsernameText: UILabel!
    
    let $ = Dependencies.sharedDependencies
    var disposeBag = DisposeBag()

    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
    
    func putImage(url: String) {
        observableForLoadingImage(url)
            .subscribeNext { [unowned self] image in
                self.twitterAvatarView.image = image
            }
            .addDisposableTo(disposeBag)
    }
    
    // MARK: - observable
    
    private func observableForLoadingImage(imageUrl: String) -> Observable<UIImage?> {
        let url = NSURL(string: imageUrl)!
        let request = NSURLRequest(URL: url)
        return NSURLSession.sharedSession().rx_data(request)
            .observeOn($.backgroundWorkScheduler)
            .map { data in
                UIImage(data: data)
            }
            .observeOn($.mainScheduler)
    }

}
