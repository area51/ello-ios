////
///  OmnibarCacheData.swift
//

open class OmnibarCacheData: NSObject, NSCoding {
    open var regions: [NSObject]

    public override init() {
        regions = [NSObject]()
        super.init()
    }

// MARK: NSCoding

    open func encode(with encoder: NSCoder) {
        encoder.encode(regions, forKey: "regions")
    }

    required public init?(coder: NSCoder) {
        let decoder = Coder(coder)
        regions = decoder.decodeKey("regions")
        super.init()
    }

}
