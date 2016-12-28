////
///  StyledLabel.swift
//

open class StyledLabel: UILabel {
    public enum FontFamily {
        case small
        case normal
        case large
        case largeBold
        case bold

        var font: UIFont {
            switch self {
            case .small: return UIFont.defaultFont(12)
            case .normal: return UIFont.defaultFont()
            case .large: return UIFont.defaultFont(18)
            case .largeBold: return UIFont.defaultBoldFont(18)
            case .bold: return UIFont.defaultBoldFont()
            }
        }
    }

    public struct Style {
        let backgroundColor: UIColor
        let textColor: UIColor
        let fontFamily: FontFamily

        var font: UIFont {
            return fontFamily.font
        }

        public init(
            textColor: UIColor,
            backgroundColor: UIColor = .clear,

            fontFamily: FontFamily = .normal
        ) {
            self.textColor = textColor
            self.backgroundColor = backgroundColor

            self.fontFamily = fontFamily
        }
    }

    struct Size {
        static let extraBottomMargin: CGFloat = 10
    }

    open override var text: String? {
        didSet { updateStyle() }
    }
    open var style: Style = .Default {
        didSet { updateStyle() }
    }
    open var styleName: String = "Default" {
        didSet { style = Style.byName(styleName) }
    }

    fileprivate func updateStyle() {
        backgroundColor = style.backgroundColor

        font = style.font
        textColor = style.textColor

        if let text = text {
            attributedText = NSAttributedString(label: text, style: style)
        }
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        updateStyle()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        updateStyle()
    }

    convenience init(style: Style) {
        self.init()
        self.style = style
        updateStyle()
    }
}

// MARK: UIView Overrides
extension StyledLabel {

    fileprivate func heightForWidth(_ width: CGFloat) -> CGFloat {
        return (attributedText?.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil).size.height).map(ceil) ?? 0
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = heightForWidth(size.width) + Size.extraBottomMargin
        return size
    }
}

extension StyledLabel.Style {
    public static let Default = StyledLabel.Style(
        textColor: .black
        )
    public static let SmallWhite = StyledLabel.Style(
        textColor: .white,
        fontFamily: .small
        )
    public static let White = StyledLabel.Style(
        textColor: .white
        )
    public static let BoldWhite = StyledLabel.Style(
        textColor: .white,
        fontFamily: .bold
        )
    public static let LargeWhite = StyledLabel.Style(
        textColor: .white,
        fontFamily: .largeBold
        )
    public static let Black = StyledLabel.Style(
        textColor: .black
        )
    public static let Large = StyledLabel.Style(
        textColor: .black,
        fontFamily: .largeBold
        )
    public static let Gray = StyledLabel.Style(
        textColor: .greyA()
        )
    public static let LightGray = StyledLabel.Style(
        textColor: UIColor(hex: 0x9a9a9a)
        )
    public static let LargePlaceholder = StyledLabel.Style(
        textColor: .greyC(),
        fontFamily: .large
        )
    public static let Error = StyledLabel.Style(
        textColor: .red
        )

    public static func byName(_ name: String) -> StyledLabel.Style {
        switch name {
        case "SmallWhite": return .SmallWhite
        case "White": return .White
        case "BoldWhite": return .BoldWhite
        case "LargeWhite": return .LargeWhite

        case "Black": return .Black
        case "Large": return .Large

        case "Gray": return .Gray
        case "LightGray": return .LightGray

        case "Error": return .Error

        default: return .Default
        }
    }
}
