//
//  CoordinatorProtocol.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import UIKit

protocol Coordintator: AnyObject {
    var childCoordinators: [Coordintator] {get set}
    var navigationController: UINavigationController? {get set}
    
    func start()
}
