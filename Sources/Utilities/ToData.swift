////
///  ToData.swift
//

public protocol ToData {
    func toData() -> Data?
}


extension Data : ToData {
    public func toData() -> Data? {
        return self
    }
}


extension String : ToData {
    public func toData() -> Data? {
        return self.data(using: String.Encoding.utf8)
    }
}


extension UIImage : ToData {
    public func toData() -> Data? {
        return UIImagePNGRepresentation(self)
    }
}
