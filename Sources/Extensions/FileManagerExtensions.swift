////
///  FileManagerExtensions.swift
//

import Foundation

public extension FileManager {

    class func ElloDocumentsDir() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
}
