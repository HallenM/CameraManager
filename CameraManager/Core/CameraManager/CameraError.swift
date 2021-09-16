//
//  CameraError.swift
//  CameraManager
//
//  Created by Moshkina on 09.09.2021.
//

import Foundation

class CameraError: LocalizedError {
    let code: Int
    let errorDescription: String?
    
    init(code: Int, description: String) {
        self.code = code
        self.errorDescription = description
    }
}

extension CameraError: CustomStringConvertible {
    var description: String {
        return "\(CameraError.self): \(localizedDescription), code: \(code)"
    }
}
