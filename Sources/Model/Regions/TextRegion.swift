////
///  TextRegion.swift
//

import Crashlytics
import Foundation
import SwiftyJSON

let TextRegionVersion = 1

@objc(TextRegion)
public final class TextRegion: JSONAble, Regionable {
    public var isRepost: Bool = false

    public let content: String

// MARK: Initialization

    public init(content: String) {
        self.content = content
        super.init(version: TextRegionVersion)
    }

// MARK: NSCoding

    public override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(content, forKey: "content")
        coder.encodeObject(isRepost, forKey: "isRepost")
        super.encode(with: coder.coder)
    }

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        self.content = decoder.decodeKey("content")
        self.isRepost = decoder.decodeKey("isRepost")
        super.init(coder: decoder.coder)
    }

// MARK: JSONAble

    override public class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        let json = JSON(data)
        Crashlytics.sharedInstance().setObjectValue(json.rawString(), forKey: CrashlyticsKey.textRegionFromJSON.rawValue)
        let content = json["data"].stringValue
        return TextRegion(content: content)
    }

// MARK: Regionable

    public var kind: String { return RegionKind.text.rawValue }

    public func coding() -> NSCoding {
        return self
    }

    public func toJSON() -> [String: AnyObject] {
        return [
            "kind": self.kind as AnyObject,
            "data": self.content as AnyObject
        ]
    }
}

extension TextRegion {
    override public var description: String {
        return "<\(type(of: self)): \"\(content)\">"
    }

    override public var debugDescription: String { return description }
}
