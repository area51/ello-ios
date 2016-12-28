////
///  SearchString.swift
//

import SwiftyJSON

let SearchStringVersion: Int = 1

@objc(SearchString)
public final class SearchString: JSONAble {
    public var text: String

    public init(text: String) {
        self.text = text
        super.init(version: SearchStringVersion)
    }

    public required init(coder: NSCoder) {
        let decoder = Coder(coder)
        self.text = decoder.decodeKey("text")
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        let encoder = Coder(coder)
        encoder.encodeObject(text, forKey: "text")
        super.encode(with: coder)
    }

    override public class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        let json = JSON(data)
        return SearchString(text: json["text"].string ?? "")
    }

}
