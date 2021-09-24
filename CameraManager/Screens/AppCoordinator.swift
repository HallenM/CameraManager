//
//  AppCoordinator.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import UIKit

class AppCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    
    var navigationController: UINavigationController?
    
    var tabBarController: UITabBarController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func start() {
        let tabBarController = UITabBarController()
        
        let cameraCoordinator = CameraCoordinator()
        childCoordinators.append(cameraCoordinator)
        
        cameraCoordinator.start()
        
        let videoListCoordinator = VideoListCordinator()
        childCoordinators.append(videoListCoordinator)
        
        videoListCoordinator.start()
        
        guard let cameraViewController = cameraCoordinator.navigationController else { return }
        guard let videoListViewController = videoListCoordinator.navigationController else { return }
        
        tabBarController.viewControllers = [cameraViewController, videoListViewController]
        
        self.navigationController?.pushViewController(tabBarController, animated: true)
        
        self.tabBarController = tabBarController
    }
    
}
