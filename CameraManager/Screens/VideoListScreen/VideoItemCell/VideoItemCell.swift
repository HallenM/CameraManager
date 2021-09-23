//
//  VideoItemCell.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import UIKit

class VideoItemCell: UITableViewCell {

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    var cellViewModel: VideoItemCellViewModel?
    
    func setCell() {
        thumbnailImageView.image = cellViewModel?.thumbnail
        titleLabel.text = cellViewModel?.title
    }
    
}
