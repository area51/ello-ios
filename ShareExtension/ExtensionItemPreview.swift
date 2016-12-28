////
///  ExtensionItemPreview.swift
//

import UIKit

public struct ExtensionItemPreview {
    public let image: UIImage?
    public let imagePath: URL?
    public let text: String?
    public let gifData: Data?

    public init(image: UIImage? = nil, imagePath: URL? = nil, text: String? = nil, gifData: Data? = nil) {
        self.image = image
        self.imagePath = imagePath
        self.text = text
        self.gifData = gifData
    }

    public var description: String {
        return "image: \(self.image), imagePath: \(self.imagePath) text: \(self.text) gif: \(self.gifData == nil)"
    }
}

public func ==(lhs: ExtensionItemPreview, rhs: ExtensionItemPreview) -> Bool {
    return lhs.image == rhs.image && lhs.imagePath == rhs.imagePath && lhs.text == rhs.text && lhs.gifData == rhs.gifData
}

