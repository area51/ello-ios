////
///  JSONAble.swift
//

import YapDatabase
import Foundation

public typealias FromJSONClosure = ([String: AnyObject]) -> JSONAble

let JSONAbleVersion = 1

protocol JSONSaveable {
    var uniqueId: String? { get }
    var tableId: String? { get }
}

@objc(JSONAble)
open class JSONAble: NSObject, NSCoding {
    // links
    open var links: [String: AnyObject]?
    open let version: Int

    public init(version: Int) {
        self.version = version
        super.init()
    }

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        self.links = decoder.decodeOptionalKey("links")
        self.version = decoder.decodeKey("version")
    }

    open func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(links, forKey: "links")
        coder.encodeObject(version, forKey: "version")
    }

    open class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        return JSONAble(version: JSONAbleVersion)
    }

    open func merge(_ other: JSONAble) -> JSONAble {
        return other
    }
}

// MARK: Links methods to get JSONAbles

extension JSONAble {
    public func getLinkObject(_ identifier: String) -> JSONAble? {
        var obj: JSONAble?
        if let id = links?[identifier]?["id"] as? String,
            let collection = links?[identifier]?["type"] as? String
        {
            ElloLinkedStore.sharedInstance.readConnection.read { transaction in
                obj = transaction.object(forKey: id, inCollection: collection) as? JSONAble
            }
        }
        else if let id = links?[identifier] as? String {
            ElloLinkedStore.sharedInstance.readConnection.read { transaction in
                obj = transaction.object(forKey: id, inCollection: identifier) as? JSONAble
            }
        }
        return obj
    }

    public func getLinkArray(_ identifier: String) -> [JSONAble] {

        guard let ids =
            self.links?[identifier] as? [String] ??
            self.links?[identifier]?["ids"] as? [String]
        else { return [] }

        var arr = [JSONAble]()
        ElloLinkedStore.sharedInstance.readConnection.read { transaction in
            for key in ids {
                if let jsonable = transaction.object(forKey: key, inCollection: identifier) as? JSONAble {
                    arr.append(jsonable)
                }
            }
        }
        return arr
    }

    public func addLinkObject(_ identifier: String, key: String, type: MappingType) {
        if links == nil { links = [String: AnyObject]() }
        links![identifier] = ["id": key, "type": type.rawValue] as AnyObject

    }

    public func addLinkObject(_ model: JSONAble, identifier: String, key: String, type: MappingType) {
        addLinkObject(identifier, key: key, type: type)
        ElloLinkedStore.sharedInstance.setObject(model, forKey: key, type: type)
    }

    public func clearLinkObject(_ identifier: String) {
        if links == nil { links = [String: AnyObject]() }
        links![identifier] = nil
    }

    public func addLinkArray(_ identifier: String, array: [String], type: MappingType) {
        if links == nil { links = [String: AnyObject]() }
        links![identifier] = ["ids": array, "type": type.rawValue] as AnyObject
    }
}
