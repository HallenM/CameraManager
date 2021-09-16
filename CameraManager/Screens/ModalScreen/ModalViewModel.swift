//
//  ModalViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 14.09.2021.
//

import UIKit

class ModalViewModel {
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func getUrl() -> URL {
        return url
    }
}
