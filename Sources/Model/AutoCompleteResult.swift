////
///  AutoCompleteResult.swift
//

import Crashlytics
import SwiftyJSON

// version 1: initial
// version 2: added image
let AutoCompleteResultVersion: Int = 2

@objc(AutoCompleteResult)
public final class AutoCompleteResult: JSONAble {

    public var name: String?
    public var url: URL?
    public var image: UIImage?

    // MARK: Initialization

    public init(name: String?) {
        self.name = name
        super.init(version: AutoCompleteResultVersion)
    }

    public convenience init(name: String, url: String) {
        self.init(name: name)
        self.url = URL(string: url)
    }

    // MARK: NSCoding
    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        self.url = decoder.decodeOptionalKey("url")
        self.name = decoder.decodeOptionalKey("name")
        let version: Int = decoder.decodeKey("version")
        if version > 1 {
            self.image = decoder.decodeOptionalKey("image")
        }
        super.init(coder: decoder.coder)
    }

    public override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(url, forKey: "url")
        coder.encodeObject(name, forKey: "name")
        coder.encodeObject(image, forKey: "image")
        super.encode(with: coder.coder)
    }

    // MARK: JSONAble

    override public class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        let json = JSON(data)
        Crashlytics.sharedInstance().setObjectValue(json.rawString(), forKey: CrashlyticsKey.autoCompleteResultFromJSON.rawValue)
        let name = json["name"].string ?? json["location"].string
        let result = AutoCompleteResult(name: name)
        if let imageUrl = json["image_url"].string,
            let url = URL(string: imageUrl)
        {
            result.url = url
        }
        else if json["location"].string != nil {
            result.image = InterfaceImage.marker.normalImage
        }
        return result
    }
}
