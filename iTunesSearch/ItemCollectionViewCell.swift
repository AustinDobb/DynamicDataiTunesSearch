//
//  ItemCollectionViewCell.swift
//  iTunesSearch
//
//  Created by Austin Dobberfuhl on 1/9/24.
//

import UIKit

class ItemCollectionViewCell: UICollectionViewCell, ItemDisplaying {
 
    @IBOutlet weak var itemImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var detailLabel: UILabel!
    
}
