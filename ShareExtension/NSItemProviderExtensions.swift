////
///  NSItemProviderExtensions.swift
//

import Foundation
import MobileCoreServices

public extension NSItemProvider {

    public func isURL() -> Bool {
        return self.hasItemConformingToTypeIdentifier(String(kUTTypeURL))
    }
    public func isImage() -> Bool {
        return self.hasItemConformingToTypeIdentifier(String(kUTTypeImage))
    }

    public func isText() -> Bool {
        return self.hasItemConformingToTypeIdentifier(String(kUTTypeText))
    }

    public func loadText(_ options: [AnyHashable: Any]?, completion: NSItemProvider.CompletionHandler?) {
        self.loadItem(forTypeIdentifier: String(kUTTypeText), options: options, completionHandler: completion)
    }

    public func loadURL(_ options: [AnyHashable: Any]?, completion: NSItemProvider.CompletionHandler?) {
        self.loadItem(forTypeIdentifier: String(kUTTypeURL), options: options, completionHandler: completion)
    }

    public func loadPreview(_ options: [AnyHashable: Any]!, completion: NSItemProvider.CompletionHandler!) {
        self.loadPreviewImage(options: options, completionHandler: completion)
    }

    public func loadImage(_ options: [AnyHashable: Any]!, completion: NSItemProvider.CompletionHandler!) {
        self.loadItem(forTypeIdentifier: String(kUTTypeImage), options: options, completionHandler: completion)
    }
}
