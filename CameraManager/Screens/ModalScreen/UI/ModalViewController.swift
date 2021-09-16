//
//  ModalViewController.swift
//  CameraManager
//
//  Created by Moshkina on 14.09.2021.
//

import UIKit
import AVFoundation

class ModalViewController: UIViewController {
    
    @IBOutlet private weak var playerView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    
    weak var modalViewModel: ModalViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = modalViewModel?.getUrl() {
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
