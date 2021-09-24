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
        
        let icon = UITabBarItem(title: "Video List", image: UIImage(systemName: "tray"), selectedImage: UIImage(systemName: "tray.fill"))
        videoListViewController.tabBarItem = icon
        
        videoListViewModel = VideoListViewModel()
        videoListViewModel?.viewDelegate = videoListViewController
        videoListViewModel?.actionDelegate = self
        
        videoListViewController.viewModel = videoListViewModel
        
        navigationController?.pushViewController(videoListViewController, animated: true)
    }
}

extension VideoListCordinator: VideoListCordinatorActionDelegate {
    func showVideo(_ sender: VideoListViewModelProtocol, video: Video) {
        
    }
}
