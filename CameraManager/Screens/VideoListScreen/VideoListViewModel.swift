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
    
    func initVideoListViewModel()
    
    func getCount() -> Int
    func getCellViewModel(index: Int) -> VideoItemCellViewModel
    func getTitle(index: Int) -> String
    
    func didTapOnCell(index: Int)
    
    func removeDataInCell(index: Int)
}

protocol VideoListViewModelDisplayDelegate: AnyObject {
    func removeCell(index: Int)
}

protocol VideoListCordinatorActionDelegate: AnyObject {
    func showVideo(_ sender: VideoListViewModelProtocol, video: Video)
}

class VideoListViewModel: VideoListViewModelProtocol {
    
    weak var viewDelegate: VideoListViewModelDisplayDelegate?
    weak var actionDelegate: VideoListCordinatorActionDelegate?
    
    private var cellViewModels: [VideoItemCellViewModel] = []
    
    init() {
        initVideoListViewModel()
    }
    
    func initVideoListViewModel() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()
            let objects = try context.fetch(fetchRequest)
            cellViewModels = []
            for object in objects {
                cellViewModels.append(VideoItemCellViewModel(video: object))
            }
            cellViewModels = cellViewModels.sorted(by: { $0.videoData.creationAt ?? Date() > $1.videoData.creationAt ?? Date() })
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
    
    func getTitle(index: Int) -> String {
        return cellViewModels[index].title ?? ""
    }
    
    func didTapOnCell(index: Int) {
        actionDelegate?.showVideo(self, video: cellViewModels[index].videoData)
    }
    
    func removeDataInCell(index: Int) {
        removeVideoInCodeData(index: index)
        cellViewModels.remove(at: index)
        viewDelegate?.removeCell(index: index)
    }
    
    func removeVideoInCodeData(index: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        context.delete(cellViewModels[index].videoData)
        appDelegate.saveContext(backgroundContext: context)
    }
}
