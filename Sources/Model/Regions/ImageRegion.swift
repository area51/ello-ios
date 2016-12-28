////
///  ImageRegion.swift
//

import Crashlytics
import Foundation
import SwiftyJSON

let ImageRegionVersion = 1

@objc(ImageRegion)
public final class ImageRegion: JSONAble, Regionable {
    public var isRepost: Bool  = false

    // required
    public let alt: String?
    // optional
    public var url: URL?
    public var buyButtonURL: URL?

    // links
    public var asset: Asset? { return getLinkObject("assets") as? Asset }

// MARK: Initialization

    public init(alt: String?)
    {
        self.alt = alt
        super.init(version: ImageRegionVersion)
    }

// MARK: NSCoding

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        // required
        self.isRepost = decoder.decodeKey("isRepost")
        // optional
        self.alt = decoder.decodeOptionalKey("alt")
        self.url = decoder.decodeOptionalKey("url")
        self.buyButtonURL = decoder.decodeOptionalKey("buyButtonURL")
        super.init(coder: decoder.coder)
    }

    public override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        // required
        coder.encodeObject(alt, forKey: "alt")
        coder.encodeObject(isRepost, forKey: "isRepost")
        // optional
        coder.encodeObject(url, forKey: "url")
        coder.encodeObject(buyButtonURL, forKey: "buyButtonURL")
        super.encode(with: coder.coder)
    }

// MARK: JSONAble

    override public class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        let json = JSON(data)
        Crashlytics.sharedInstance().setObjectValue(json.rawString(), forKey: CrashlyticsKey.imageRegionFromJSON.rawValue)
        // create region
        let imageRegion = ImageRegion(
            alt: json["data"]["alt"].string
            )
        // optional
        if var urlStr = json["data"]["url"].string {
            if urlStr.hasPrefix("//") {
                urlStr = "https:\(urlStr)"
            }
            imageRegion.url = URL(string: urlStr)
        }
        if let urlStr = json["link_url"].string {
            imageRegion.buyButtonURL = URL(string: urlStr)
        }
        // links
        imageRegion.links = data["links"] as? [String: AnyObject]
        return imageRegion
    }

// MARK: Regionable

    public var kind: String { return RegionKind.image.rawValue }

    public func coding() -> NSCoding {
        return self
    }

    public func toJSON() -> [String: AnyObject] {
        var json: [String: AnyObject]
        if let url = self.url?.absoluteString {
            json = [
                "kind": self.kind as AnyObject,
                "data": [
                    "alt": alt ?? "",
                    "url": url
                ] as AnyObject,
            ]
        }
        else {
            json = [
                "kind": self.kind as AnyObject,
                "data": [:] as AnyObject
            ]
        }

        if let buyButtonURL = buyButtonURL {
            json["link_url"] = buyButtonURL.absoluteString as AnyObject?
        }
        return json
    }
}
