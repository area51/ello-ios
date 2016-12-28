////
///  StreamSeeMoreCommentsCell.swift
//

import Foundation


open class StreamSeeMoreCommentsCell: UICollectionViewCell {
    static let reuseIdentifier = "StreamSeeMoreCommentsCell"

    @IBOutlet weak open var buttonContainer: UIView!
    @IBOutlet weak open var seeMoreButton: UIButton!

    override open func awakeFromNib() {
        super.awakeFromNib()
        style()
    }

    fileprivate func style() {
        buttonContainer.backgroundColor = .greyA()
        seeMoreButton.setTitleColor(UIColor.greyA(), for: .normal)
        seeMoreButton.backgroundColor = .white
        seeMoreButton.titleLabel?.font = .defaultFont()
    }

}
