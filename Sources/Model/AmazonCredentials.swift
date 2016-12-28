////
///  AmazonCredentials.swift
//

import Crashlytics

let AmazonCredentialsVersion = 2

@objc(AmazonCredentials)
open class AmazonCredentials: JSONAble {
    open let accessKey: String
    open let endpoint: String
    open let policy: String
    open let prefix: String
    open let signature: String

    public init(accessKey: String, endpoint: String, policy: String, prefix: String, signature: String) {
        self.accessKey = accessKey
        self.endpoint = endpoint
        self.policy = policy
        self.prefix = prefix
        self.signature = signature
        super.init(version: AmazonCredentialsVersion)
    }

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        let version: Int = decoder.decodeKey("version")
        if version > 1 {
            accessKey = decoder.decodeKey("accessKey")
            endpoint = decoder.decodeKey("endpoint")
            policy = decoder.decodeKey("policy")
            prefix = decoder.decodeKey("prefix")
            signature = decoder.decodeKey("signature")
        }
        else {
            accessKey = ""
            endpoint = ""
            policy = ""
            prefix = ""
            signature = ""
        }
        super.init(coder: aDecoder)
    }

    open override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(accessKey, forKey: "accessKey")
        coder.encodeObject(endpoint, forKey: "endpoint")
        coder.encodeObject(policy, forKey: "policy")
        coder.encodeObject(prefix, forKey: "prefix")
        coder.encodeObject(signature, forKey: "signature")
    }

    override open class func fromJSON(_ data: [String : AnyObject]) -> JSONAble {
        Crashlytics.sharedInstance().setObjectValue(data.description, forKey: CrashlyticsKey.amazonCredentialsFromJSON.rawValue)
        return AmazonCredentials(
            accessKey: data["access_key"] as! String,
            endpoint:  data["endpoint"] as! String,
            policy:    data["policy"] as! String,
            prefix:    data["prefix"] as! String,
            signature: data["signature"] as! String
        )
    }
}

extension AmazonCredentials: JSONSaveable {
    var uniqueId: String? { if let id = tableId { return "AmazonCredentials-\(id)" } ; return nil }
    var tableId: String? { return accessKey }

}
