////
///  EmbedRegion.swift
//

import Crashlytics
import Foundation
import SwiftyJSON

let EmbedRegionVersion = 1

public enum EmbedType: String {
    case codepen = "codepen"
    case dailymotion = "dailymotion"
    case mixcloud = "mixcloud"
    case soundcloud = "soundcloud"
    case youtube = "youtube"
    case vimeo = "vimeo"
    case uStream = "ustream"
    case bandcamp = "bandcamp"
    case unknown = "unknown"
}

@objc(EmbedRegion)
public final class EmbedRegion: JSONAble, Regionable {
    public var isRepost: Bool = false

    // active record
    public let id: String
    // required
    public let service: EmbedType
    public let url: URL
    public let thumbnailSmallUrl: URL
    public let thumbnailLargeUrl: URL
    // computed
    public var isAudioEmbed: Bool {
        return service == EmbedType.mixcloud || service == EmbedType.soundcloud || service == EmbedType.bandcamp
    }

    // MARK: Initialization

    public init(
        id: String,
        service: EmbedType,
        url: URL,
        thumbnailSmallUrl: URL,
        thumbnailLargeUrl: URL
        )
    {
        self.id = id
        self.service = service
        self.url = url
        self.thumbnailSmallUrl = thumbnailSmallUrl
        self.thumbnailLargeUrl = thumbnailLargeUrl
        super.init(version: EmbedRegionVersion)
    }

    // MARK: NSCoding

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        // active record
        self.id = decoder.decodeKey("id")
        // required
        self.isRepost = decoder.decodeKey("isRepost")
        let serviceRaw: String = decoder.decodeKey("serviceRaw")
        self.service = EmbedType(rawValue: serviceRaw) ?? EmbedType.unknown
        self.url = decoder.decodeKey("url")
        self.thumbnailSmallUrl = decoder.decodeKey("thumbnailSmallUrl")
        self.thumbnailLargeUrl = decoder.decodeKey("thumbnailLargeUrl")
        super.init(coder: decoder.coder)
    }

    public override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        // active record
        coder.encodeObject(id, forKey: "id")
        // required
        coder.encodeObject(isRepost, forKey: "isRepost")
        coder.encodeObject(service.rawValue, forKey: "serviceRaw")
        coder.encodeObject(url, forKey: "url")
        coder.encodeObject(thumbnailSmallUrl, forKey: "thumbnailSmallUrl")
        coder.encodeObject(thumbnailLargeUrl, forKey: "thumbnailLargeUrl")
        super.encode(with: coder.coder)
    }

    // MARK: JSONAble

    override public class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        let json = JSON(data)
        Crashlytics.sharedInstance().setObjectValue(json.rawString(), forKey: CrashlyticsKey.embedRegionFromJSON.rawValue)
        // create region
        let embedRegion = EmbedRegion(
            id: json["data"]["id"].stringValue,
            service: EmbedType(rawValue: json["data"]["service"].stringValue) ?? .unknown,
            url: URL(string: json["data"]["url"].stringValue) ?? URL(string: "https://ello.co/404")!,
            thumbnailSmallUrl: URL(string: json["data"]["thumbnail_small_url"].stringValue) ?? URL(string: "https://ello.co/404/jibberish.jpg")!,
            thumbnailLargeUrl: URL(string: json["data"]["thumbnail_large_url"].stringValue) ?? URL(string: "https://ello.co/404/jibberish.jpg")!
        )
        if embedRegion.url.absoluteString.hasPrefix("https://ello.co/404") || embedRegion.thumbnailSmallUrl.absoluteString.hasPrefix("https://ello.co/404") || embedRegion.thumbnailLargeUrl.absoluteString.hasPrefix("https://ello.co/404") {
            // send data to segment to try to get more data about this
            Tracker.sharedTracker.createdAtCrash("EmbedRegion", json: json.rawString())
        }
        return embedRegion
    }

// MARK: Regionable

    public var kind: String { return RegionKind.embed.rawValue }

    public func coding() -> NSCoding {
        return self
    }

    public func toJSON() -> [String: AnyObject] {
        return [
            "kind": self.kind as AnyObject,
            "data": [
                "url": self.url.absoluteString
                ] as AnyObject,
        ]
    }
}
