//
//  VideoListViewController.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import UIKit

class VideoListViewController: UIViewController {
    
    @IBOutlet private weak var videoTableView: UITableView!
    
    var viewModel: VideoListViewModelProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoTableView.register(UINib(nibName: "VideoItemCell", bundle: nil), forCellReuseIdentifier: "VideoItemCell")
        videoTableView.dataSource = self
        videoTableView.delegate = self
        videoTableView.estimatedRowHeight = UITableView.automaticDimension
        videoTableView.rowHeight = UITableView.automaticDimension
    }
}

extension VideoListViewController: VideoListViewModelDisplayDelegate {
    
}

extension VideoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.didTapOnCell(index: indexPath.row)
    }
}

extension VideoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.getCount() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoItemCell") as! VideoItemCell
        
        if let cellViewModel = viewModel?.getCellViewModel(index: indexPath.row) {
            cell.cellViewModel = cellViewModel
            cell.setCell()
        }
        
        return cell
    }
}
