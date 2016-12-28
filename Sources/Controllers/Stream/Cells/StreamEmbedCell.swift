////
///  StreamEmbedCell.swift
//

open class StreamEmbedCell: StreamImageCell {
    static let reuseEmbedIdentifier = "StreamEmbedCell"

    @IBOutlet weak var playIcon: UIImageView!
    open var embedUrl: URL?

    @IBAction override func imageTapped() {
        if let url = embedUrl {
            postNotification(ExternalWebNotification, value: url.absoluteString)
        }
    }

    open func setPlayImageIcon(_ icon: InterfaceImage) {
        playIcon.image = icon.normalImage
    }
}
