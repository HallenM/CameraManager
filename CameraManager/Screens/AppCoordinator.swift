//
//  AppCoordinator.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import UIKit

class AppCoordinator: Coordintator {
    
    var childCoordinators: [Coordintator] = []
    
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
        
        guard let cameraViewController = cameraCoordinator.navigationController else { return }
        tabBarController.viewControllers = [cameraViewController]
        
        cameraCoordinator.start()
        
        self.navigationController?.pushViewController(tabBarController, animated: true)
        
        self.tabBarController = tabBarController
    }
    
}
