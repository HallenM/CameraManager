//
//  CoordinatorProtocol.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] {get set}
    var navigationController: UINavigationController? {get set}
    
    func start()
}
