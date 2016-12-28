////
///  Relationship.swift
//

import Crashlytics
import Foundation
import SwiftyJSON

let RelationshipVersion = 1

@objc(Relationship)
public final class Relationship: JSONAble {

    // active record
    public let id: String
    public let createdAt: Date
    // required
    public let ownerId: String
    public let subjectId: String
    // computed
    public var owner: User? {
        return ElloLinkedStore.sharedInstance.getObject(self.ownerId, type: .usersType) as? User
    }
    public var subject: User? {
        return ElloLinkedStore.sharedInstance.getObject(self.subjectId, type: .usersType) as? User
    }

    public init(id: String, createdAt: Date, ownerId: String, subjectId: String) {
        self.id = id
        self.createdAt = createdAt
        self.ownerId = ownerId
        self.subjectId = subjectId
        super.init(version: RelationshipVersion)
    }

// MARK: NSCoding

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        // active record
        self.id = decoder.decodeKey("id")
        self.createdAt = decoder.decodeKey("createdAt")
        // required
        self.ownerId = decoder.decodeKey("ownerId")
        self.subjectId = decoder.decodeKey("subjectId")
        super.init(coder: decoder.coder)
    }

    public override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        // active record
        coder.encodeObject(id, forKey: "id")
        coder.encodeObject(createdAt, forKey: "createdAt")
        // required
        coder.encodeObject(ownerId, forKey: "ownerId")
        coder.encodeObject(subjectId, forKey: "subjectId")
        super.encode(with: coder.coder)
    }

// MARK: JSONAble

    override public class func fromJSON(_ data: [String: AnyObject]) -> JSONAble {
        let json = JSON(data)
        Crashlytics.sharedInstance().setObjectValue(json.rawString(), forKey: CrashlyticsKey.relationshipFromJSON.rawValue)
        var createdAt: Date
        if let date = json["created_at"].stringValue.toDate() {
            // good to go
            createdAt = date
        }
        else {
            createdAt = Date()
            // send data to segment to try to get more data about this
            Tracker.sharedTracker.createdAtCrash("Relationship", json: json.rawString())
        }
        let relationship = Relationship(
            id: json["id"].stringValue,
            createdAt: createdAt,
            ownerId: json["links"]["owner"]["id"].stringValue,
            subjectId: json["links"]["subject"]["id"].stringValue
        )
        return relationship
    }
}

extension Relationship: JSONSaveable {
    var uniqueId: String? { if let id = tableId { return "Relationship-\(id)" } ; return nil }
    var tableId: String? { return id }

}
