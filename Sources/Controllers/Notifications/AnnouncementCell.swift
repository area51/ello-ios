////
///  AnnouncementCell.swift
//

import SnapKit


class AnnouncementCell: UICollectionViewCell {
    static let reuseIdentifier = "AnnouncementCell"

    struct Size {
        static let margins: CGFloat = 15
        static let imageSize: CGFloat = 80
        static let textLeadingMargin: CGFloat = 15
        static let textVerticalMargin: CGFloat = 15
        static let closeButtonMargin: CGFloat = 15
        static let closeButtonSize: CGFloat = 50
    }

    public struct Config {
        var title: String?
        var body: String?
        var imageURL: URL?
        var image: UIImage? // for testing
        var callToAction: String?

        public init() {}
    }

    weak var delegate: AnnouncementCellDelegate?

    open var config = Config() {
        didSet {
            titleLabel.text = config.title
            bodyLabel.text = config.body
            callToActionButton.title = config.callToAction

            if let url = config.imageURL {
                imageView.pin_setImage(from: url) { _ in }
            }
            else {
                imageView.pin_cancelImageDownload()
                imageView.image = config.image // for testing, nice to be able to assign an image sync'ly
            }
        }
    }

    fileprivate let imageView = FLAnimatedImageView()
    fileprivate let closeButton = UIButton()
    fileprivate let titleLabel = StyledLabel(style: .BoldWhite)
    fileprivate let bodyLabel = StyledLabel(style: .White)
    fileprivate let callToActionButton = StyledButton(style: .WhiteUnderlined)

    override init(frame: CGRect) {
        super.init(frame: frame)
        style()
        bindActions()
        arrange()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func style() {
        contentView.backgroundColor = .black
        closeButton.setImages(.x)

        titleLabel.numberOfLines = 0
        bodyLabel.numberOfLines = 0
        callToActionButton.contentHorizontalAlignment = .left
        callToActionButton.isUserInteractionEnabled = false
    }

    func bindActions() {
        closeButton.addTarget(self, action: #selector(markAsRead), for: .touchUpInside)
    }

    func arrange() {
        contentView.addSubview(imageView)
        contentView.addSubview(closeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(callToActionButton)

        imageView.snp.makeConstraints { make in
            make.top.leading.equalTo(contentView).inset(Size.margins)
            make.width.height.equalTo(Size.imageSize)
        }
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalTo(contentView)
            make.width.height.equalTo(Size.closeButtonSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(Size.textLeadingMargin)
            make.top.equalTo(imageView)
            make.trailing.equalTo(closeButton.snp.leading)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Size.textVerticalMargin)
            make.leading.trailing.equalTo(titleLabel)
        }
        callToActionButton.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(Size.textVerticalMargin)
            make.leading.trailing.equalTo(titleLabel)
        }
    }

}

extension AnnouncementCell {
    override public func prepareForReuse() {
        config = Config()
    }
}

extension AnnouncementCell {
    func markAsRead() {
        delegate?.markAnnouncementAsRead(cell: self)
    }
}
