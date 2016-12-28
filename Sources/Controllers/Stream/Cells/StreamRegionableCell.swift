////
///  StreamRegionableCell.swift
//

import Foundation

open class StreamRegionableCell: UICollectionViewCell {
    open var leftBorder = CALayer()

    override open func awakeFromNib() {
        super.awakeFromNib()
        leftBorder.backgroundColor = UIColor.black.cgColor
    }

    open func showBorder() {
        self.layer.addSublayer(leftBorder)
    }

    open func hideBorder() {
        leftBorder.removeFromSuperlayer()
    }

    override open func layoutSubviews() {
        leftBorder.frame = CGRect(x: 15, y: 0, width: 1, height: self.bounds.height)
        super.layoutSubviews()
    }
}
