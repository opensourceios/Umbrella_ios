//
//  ChecklistReviewCell.swift
//  Umbrella
//
//  Created by Lucas Correa on 28/09/2018.
//  Copyright © 2018 Security First. All rights reserved.
//

import UIKit

protocol ChecklistReviewCellDelegate: class {
    func shareChecklist(cell: ChecklistReviewCell, indexPath: IndexPath)
}

class ChecklistReviewCell: UITableViewCell {
    
    //
    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var shareWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: ChecklistReviewCellDelegate?
    var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    //
    // MARK: - Functions
    
    /// Configure the cell with viewModel
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel
    ///   - indexPath: IndexPath
    func configure(withViewModel viewModel:ChecklistViewModel, indexPath: IndexPath) {
        self.indexPath = indexPath
        var title = ""
        var percent = ""
        self.widthConstraint.constant = 44
        self.shareWidthConstraint.constant = 40
        self.shareButton.isHidden = false
        if indexPath.section == 0 {
            let checklistChecked = viewModel.totalDoneChecklistChecked
            title = checklistChecked?.subCategoryName ?? ""
            
            print("Total Done: \(checklistChecked?.totalChecked ?? 0) / \(checklistChecked?.totalItemsChecklist ?? 0) * 100")
            if checklistChecked?.totalChecked == 0 {
                percent = "0%"
            } else {
                percent = String(format: "%.f%%", floor(Float(checklistChecked?.totalChecked ?? 0) / (Float(checklistChecked?.totalItemsChecklist ?? 0)) * 100))
            }
            self.widthConstraint.constant = 80
            self.iconImageView.image = UIImage(named: "icTotalDone")
            self.iconImageView.backgroundColor = UIColor.clear
            self.shareWidthConstraint.constant = 0
            self.shareButton.isHidden = true
        } else if indexPath.section == 1 {
            let checklistChecked = viewModel.favouriteChecklistChecked[indexPath.row]
            let iconAndColor = viewModel.difficultyIconBy(id: checklistChecked.difficultyId)
            
            self.iconImageView.image = iconAndColor.image
            self.iconImageView.backgroundColor = iconAndColor.color
            title = checklistChecked.subCategoryName
            percent = String(format: "%.f%%", floor(Float(checklistChecked.totalChecked) / (Float(checklistChecked.totalItemsChecklist)) * 100))
        } else {
            let checklistChecked = viewModel.checklistChecked[indexPath.row]
            let iconAndColor = viewModel.difficultyIconBy(id: checklistChecked.difficultyId)
            
            self.iconImageView.image = iconAndColor.image
            self.iconImageView.backgroundColor = iconAndColor.color
            title = checklistChecked.subCategoryName
            percent = String(format: "%.f%%", floor(Float(checklistChecked.totalChecked) / (Float(checklistChecked.totalItemsChecklist)) * 100))
        }
        
        self.titleLabel.text = title
        self.percentLabel.text = percent
        self.layoutIfNeeded()
    }
    
    //
    // MARK: - Actions
    
    @IBAction func shareAction(_ sender: Any) {
        self.delegate?.shareChecklist(cell: self, indexPath: self.indexPath)
    }
}
