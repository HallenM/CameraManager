//
//  VideoListCoordinator.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import UIKit

class VideoListCordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    
    var navigationController: UINavigationController?
    
    private var videoListViewModel: VideoListViewModel?
    
    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func start() {
        let videoListViewController = VideoListViewController.initFromNib()
        
        let icon = UITabBarItem(title: "Video List", image: UIImage(systemName: "list"), selectedImage: UIImage(systemName: "listFilled"))
        videoListViewController.tabBarItem = icon
        
        videoListViewModel = VideoListViewModel()
        videoListViewModel?.viewDelegate = videoListViewController
        
        videoListViewController.viewModel = videoListViewModel
        
        navigationController?.pushViewController(videoListViewController, animated: true)
    }
}
