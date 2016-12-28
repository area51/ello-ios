////
///  DrawerCell.swift
//

open class DrawerCell: UITableViewCell {
    public static let reuseIdentifier = "DrawerCell"
    @IBOutlet weak open var label: UILabel!
    @IBOutlet weak open var line: UIView!

    override open func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .grey6()
        line.backgroundColor = .grey5()
        label.font = UIFont.defaultFont()
        label.textColor = .white
    }
}

public extension DrawerCell {
    class func nib() -> UINib {
        return UINib(nibName: "DrawerCell", bundle: .none)
    }
}
