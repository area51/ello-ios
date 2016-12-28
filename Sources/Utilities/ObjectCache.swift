////
///  ObjectCache.swift
//

import Foundation

public protocol PersistentLayer {
    func setObject(_ value: Any?, forKey: String)
    func objectForKey(_ defaultName: String) -> Any?
    func removeObjectForKey(_ defaultName: String)
}

extension UserDefaults: PersistentLayer { }

open class ObjectCache<T: Any> {
    fileprivate let persistentLayer: PersistentLayer
    open var cache: [T] = []
    open let name: String

    public init(name: String) {
        self.name = name
        persistentLayer = GroupDefaults
    }

    public init(name: String, persistentLayer: PersistentLayer) {
        self.name = name
        self.persistentLayer = persistentLayer
    }

    open func append(_ item: T) {
        cache.append(item)
        persist()
    }

    open func getAll() -> [T] {
        return cache
    }

    func persist() {
        persistentLayer.setObject(cache as AnyObject?, forKey: name)
    }

    open func load() {
        cache = persistentLayer.objectForKey(name) as? [T] ?? []
    }

    open func clear() {
        persistentLayer.removeObjectForKey(name)
    }
}
