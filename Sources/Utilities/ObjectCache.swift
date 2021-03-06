////
///  ObjectCache.swift
//

import Foundation

public protocol PersistentLayer {
    func setObject(value: AnyObject?, forKey: String)
    func objectForKey(defaultName: String) -> AnyObject?
    func removeObjectForKey(defaultName: String)
}

extension NSUserDefaults: PersistentLayer { }

public class ObjectCache<T: AnyObject> {
    private let persistentLayer: PersistentLayer
    public var cache: [T] = []
    public let name: String

    public init(name: String) {
        self.name = name
        persistentLayer = GroupDefaults
    }

    public init(name: String, persistentLayer: PersistentLayer) {
        self.name = name
        self.persistentLayer = persistentLayer
    }

    public func append(item: T) {
        cache.append(item)
        persist()
    }

    public func getAll() -> [T] {
        return cache
    }

    func persist() {
        persistentLayer.setObject(cache, forKey: name)
    }

    public func load() {
        cache = persistentLayer.objectForKey(name) as? [T] ?? []
    }

    public func clear() {
        persistentLayer.removeObjectForKey(name)
    }
}
