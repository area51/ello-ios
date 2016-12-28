////
///  Authorable.swift
//


@objc
public protocol Authorable {
    var createdAt: Date { get }
    var author: User? { get }
}
