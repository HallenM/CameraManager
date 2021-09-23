//
//  VideoListViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import UIKit
import CoreData

protocol VideoListViewModelProtocol: AnyObject {
    var viewDelegate: VideoListViewModelDisplayDelegate? { get set }
    func getCount() -> Int
    func getCellViewModel(index: Int) -> VideoItemCellViewModel
    func didTapOnCell(index: Int)
}

protocol VideoListViewModelDisplayDelegate: AnyObject {
    
}

protocol VideoListCordinatorActionDelegate: AnyObject {
    func showVideo(_ sender: VideoListViewModelProtocol, video: Video)
}

class VideoListViewModel: VideoListViewModelProtocol {
    
    weak var viewDelegate: VideoListViewModelDisplayDelegate?
    weak var actionDelegate: VideoListCordinatorActionDelegate?
    
    private var cellViewModels: [VideoItemCellViewModel] = []
    
    init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                cellViewModels.append(VideoItemCellViewModel(video: object))
            }
            
//            let video = objects.last
//            var image: UIImage?
//
//            if let thumbnail = video?.thumbnail {
//                image = UIImage().toImage(data: thumbnail)
//            }
        } catch {
            print("Error CoreData: \(error)")
        }
    }
    
    func getCount() -> Int {
        return cellViewModels.count
    }
    
    func getCellViewModel(index: Int) -> VideoItemCellViewModel {
        return cellViewModels[index]
    }
    
    func didTapOnCell(index: Int) {
    }
}
