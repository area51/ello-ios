////
///  ExternalLink.swift
//


public struct ExternalLink {
    public let url: URL
    public let text: String
    public let iconURL: URL?

    public init(url: URL, text: String, iconURL: URL? = nil) {
        self.url = url
        self.text = text
        self.iconURL = iconURL
    }
}

public extension ExternalLink {
    static func fromDict(_ link: [String: String]) -> ExternalLink? {
        guard let
            urlStr = link["url"],
            let url = URL(string: urlStr),
            let text = link["text"]
        else {
            return nil
        }

        let iconURL: URL?
        if let iconURLStr = link["icon"] {
            iconURL = URL(string: iconURLStr)
        }
        else {
            iconURL = nil
        }
        return ExternalLink(url: url, text: text, iconURL: iconURL)
    }

    func toDict() -> [String: String] {
        var retVal: [String: String] = [
            "url": url.absoluteString,
            "text": text
        ]
        if let iconURL = iconURL {
            retVal["icon"] = iconURL.absoluteString
        }
        return retVal
    }
}

extension ExternalLink: Equatable {}

public func == (lhs: ExternalLink, rhs: ExternalLink) -> Bool {
    return lhs.url == rhs.url && lhs.text == rhs.text && lhs.iconURL == rhs.iconURL
}
