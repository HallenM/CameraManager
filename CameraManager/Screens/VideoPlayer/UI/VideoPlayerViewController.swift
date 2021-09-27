//
//  VideoPlayerViewController.swift
//  CameraManager
//
//  Created by Moshkina on 24.09.2021.
//

import UIKit
import AVFoundation

class VideoPlayerViewController: UIViewController {
    
    @IBOutlet private weak var playerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var creationAtLabel: UILabel!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    
    weak var playerViewModel: VideoPlayerViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = playerViewModel?.getUrl() {
            player = AVPlayer(url: url)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resize
            playerLayer?.frame = playerView.layer.bounds
            
            self.playerView.layer.addSublayer(playerLayer ?? AVPlayerLayer())
            
            player?.play()
            
            player?.actionAtItemEnd = .none
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerInfinityPlaying(notification:)),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: player?.currentItem)
            
            setVideoInfo()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func setVideoInfo() {
        if let title = playerViewModel?.getTitle(),
           let createdAt = playerViewModel?.getCreationTime() {
            titleLabel.text = titleLabel.text! + " " + title
            creationAtLabel.text = creationAtLabel.text! + " " + createdAt
        }
    }
    
    @objc func playerInfinityPlaying(notification: Notification) {
        self.player?.seek(to: .zero)
        self.player?.play()
    }
    
    @IBAction func didTapCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
