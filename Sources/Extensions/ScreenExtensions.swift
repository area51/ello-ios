////
///  ScreenExtensions.swift
//

extension UIWindow {
    class var mainWindow: UIWindow {
        return UIApplication.shared.keyWindow ?? UIWindow()
    }

    class func windowBounds() -> CGRect {
        return mainWindow.bounds
    }

    class func windowSize() -> CGSize {
        return windowBounds().size
    }

    class func windowWidth() -> CGFloat {
        return windowSize().width
    }

    class func windowHeight() -> CGFloat {
        return windowSize().height
    }

}


open class Window {
    static open func isWide(_ width: CGFloat) -> Bool {
        return width > 1000
    }
    static open var width: CGFloat { return UIWindow.mainWindow.frame.size.width }
}
