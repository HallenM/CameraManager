//
//  VideoListViewController.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import UIKit

class VideoListViewController: UIViewController {
    
    var viewModel: VideoListViewModelProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension VideoListViewController: VideoListViewModelDisplayDelegate {
    
}
