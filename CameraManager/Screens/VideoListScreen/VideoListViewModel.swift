//
//  VideoListViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import Foundation

protocol VideoListViewModelProtocol: AnyObject {
    var viewDelegate: VideoListViewModelDisplayDelegate? { get set }
}

protocol VideoListViewModelDisplayDelegate: AnyObject {
    
}

class VideoListViewModel: VideoListViewModelProtocol {
    weak var viewDelegate: VideoListViewModelDisplayDelegate?
}
