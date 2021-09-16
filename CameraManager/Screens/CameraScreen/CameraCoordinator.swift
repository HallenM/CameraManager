//
//  CameraCoordinator.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import UIKit

class CameraCoordinator: Coordintator {
    
    var childCoordinators: [Coordintator] = []
    
    var navigationController: UINavigationController?
    
    private var mainViewModel: MainViewModel?
    private var modalViewModel: ModalViewModel?
    
    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func start() {
        let cameraViewController = CameraViewController.initFromNib()
        
        let icon = UITabBarItem(title: "Camera", image: UIImage(systemName: "camera"), selectedImage: UIImage(systemName: "camera.fill"))
        cameraViewController.tabBarItem = icon
        
        mainViewModel = MainViewModel()
        mainViewModel?.viewDelegate = cameraViewController
        
        cameraViewController.viewModel = mainViewModel
        
        navigationController?.pushViewController(cameraViewController, animated: true)
    }

}
