////
///  OmnibarImageDownloadCell.swift
//

open class OmnibarImageDownloadCell: UITableViewCell {
    static let reuseIdentifier = "OmnibarImageDownloadCell"

    struct Size {
        static let height = CGFloat(100)
    }

    open let logoView = PulsingCircle()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(logoView)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        logoView.frame = contentView.bounds
    }

    override open func didMoveToSuperview() {
        logoView.pulse()
    }

}
