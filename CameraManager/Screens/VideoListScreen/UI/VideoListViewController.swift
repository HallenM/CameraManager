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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        // Add refreshControll for refreshing
        videoTableView.refreshControl = UIRefreshControl()
        videoTableView.refreshControl?.attributedTitle = NSAttributedString(string: "Updating...")
        videoTableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        
        reloadData()
    }
    
    // Sender for refreshing data in table
    @objc func handleRefreshControl(sender: AnyObject) {
        reloadData()
    }
    
    func reloadData() {
        viewModel?.initVideoListViewModel()
        DispatchQueue.main.async {
            self.videoTableView.reloadData()
            self.videoTableView.refreshControl?.endRefreshing()
        }
    }
}

extension VideoListViewController: VideoListViewModelDisplayDelegate {
    func removeCell(index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        videoTableView.deleteRows(at: [indexPath], with: .left)
    }
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let titleCell = viewModel?.getTitle(index: indexPath.row) ?? ""
            let alertController = UIAlertController(title: "Deleting cell", message: "Are you sure you want delete \(titleCell)?", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Yes", style: .default) { (_) -> Void in
                self.viewModel?.removeDataInCell(index: indexPath.row)
            }
            alertController.addAction(settingsAction)
            
            let cancelAction = UIAlertAction(title: "No", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
