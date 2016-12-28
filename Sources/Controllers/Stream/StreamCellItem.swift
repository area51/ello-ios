////
///  StreamCellItem.swift
//

import Foundation

public enum StreamCellState: CustomStringConvertible, CustomDebugStringConvertible {
    case none
    case loading
    case expanded
    case collapsed

    public var description: String {
        switch self {
        case .none: return "None"
        case .loading: return "Loading"
        case .expanded: return "Expanded"
        case .collapsed: return "Collapsed"
        }
    }
    public var debugDescription: String { return "StreamCellState.\(description)" }
}


public final class StreamCellItem: NSObject, NSCopying {
    public var jsonable: JSONAble
    public var type: StreamCellType
    public var placeholderType: StreamCellType.PlaceholderType?
    public var calculatedCellHeights = CalculatedCellHeights()
    public var state: StreamCellState = .none

    public convenience init(type: StreamCellType) {
        self.init(jsonable: JSONAble(version: 1), type: type)
    }

    public convenience init(type: StreamCellType, placeholderType: StreamCellType.PlaceholderType) {
        self.init(jsonable: JSONAble(version: 1), type: type, placeholderType: placeholderType)
    }

    public convenience init(jsonable: JSONAble, type: StreamCellType, placeholderType: StreamCellType.PlaceholderType) {
        self.init(jsonable: jsonable, type: type)
        self.placeholderType = placeholderType
    }

    public required init(jsonable: JSONAble, type: StreamCellType) {
        self.jsonable = jsonable
        self.type = type
    }

    public func copy(with zone: NSZone?) -> Any {
        let copy = type(of: self).init(
            jsonable: self.jsonable,
            type: self.type
            )
        copy.calculatedCellHeights.webContent = self.calculatedCellHeights.webContent
        copy.calculatedCellHeights.oneColumn = self.calculatedCellHeights.oneColumn
        copy.calculatedCellHeights.multiColumn = self.calculatedCellHeights.multiColumn
        return copy
    }

    public func alwaysShow() -> Bool {
        if type == .streamLoading {
            return true
        }
        return false
    }

    public override var description: String {
        switch type {
        case let .text(data):
            let text: String
            if let textRegion = data as? TextRegion {
                text = textRegion.content
            }
            else {
                text = "unknown"
            }

            return "StreamCellItem(type: \(type.name), jsonable: \(type(of: jsonable)), state: \(state), text: \(text))"
        default:
            return "StreamCellItem(type: \(type.name), jsonable: \(type(of: jsonable)), state: \(state))"
        }
    }

}


func == (lhs: StreamCellItem, rhs: StreamCellItem) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.placeholder, .placeholder):
        return lhs.placeholderType == rhs.placeholderType
    default:
        return lhs === rhs
    }
}
