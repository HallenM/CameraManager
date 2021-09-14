//
//  ModalViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 14.09.2021.
//

import UIKit

protocol ModalViewModelDisplayDelegate: AnyObject {
    
}

class ModalViewModel {
    weak var viewDelegate: ModalViewModelDisplayDelegate?
    var url: URL?
}
