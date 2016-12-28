////
///  ClearTextField.swift
//

open class ClearTextField: UITextField {
    struct Size {
        static let lineMargin: CGFloat = 5
    }

    open let onePasswordButton = OnePasswordButton()
    open var lineColor: UIColor? = .grey6() {
        didSet {
            if !isFirstResponder {
                line.backgroundColor = lineColor
            }
        }
    }
    open var selectedLineColor: UIColor? = .white {
        didSet {
            if isFirstResponder {
                line.backgroundColor = selectedLineColor
            }
        }
    }
    fileprivate var line = UIView()
    open var hasOnePassword = false {
        didSet {
            onePasswordButton.isHidden = !hasOnePassword
            setNeedsLayout()
        }
    }
    open var validationState: ValidationState = .none {
        didSet {
            rightView = UIImageView(image: validationState.imageRepresentation)
            // This nonsense below is to prevent the rightView
            // from animating into position from 0,0 and passing specs
            rightView?.frame = rightViewRect(forBounds: self.bounds)
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedSetup()
    }

    func sharedSetup() {
        backgroundColor = .clear
        font = .defaultFont(18)
        textColor = .white
        rightViewMode = .always

        addSubview(onePasswordButton)
        onePasswordButton.isHidden = !hasOnePassword
        onePasswordButton.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(-Size.lineMargin / 2)
            make.trailing.equalTo(self)
            make.size.equalTo(CGSize.minButton)
        }

        addSubview(line)
        line.backgroundColor = lineColor
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }

    override open var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if size.height != UIViewNoIntrinsicMetric {
            size.height += Size.lineMargin
        }
        return size
    }

    override open func drawPlaceholder(in rect: CGRect) {
        placeholder?.draw(in: rect, withAttributes: [
            NSFontAttributeName: UIFont.defaultFont(18),
            NSForegroundColorAttributeName: UIColor.white,
        ])
    }

    override open func becomeFirstResponder() -> Bool {
        line.backgroundColor = selectedLineColor
        return super.becomeFirstResponder()
    }

    override open func resignFirstResponder() -> Bool {
        line.backgroundColor = lineColor
        return super.resignFirstResponder()
    }

// MARK: Layout rects

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return rectForBounds(bounds)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return rectForBounds(bounds)
    }

    override open func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.clearButtonRect(forBounds: bounds)
        rect.origin.x -= 10
        if hasOnePassword {
            rect.origin.x -= 44
        }
        return rect
    }

    override open func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x -= 10
        if hasOnePassword {
            rect.origin.x -= 20
        }
        return rect
    }

    fileprivate func rectForBounds(_ bounds: CGRect) -> CGRect {
        var rect = bounds.shrink(left: 15)
        if validationState.imageRepresentation != nil {
            rect = rect.shrink(left: 20)
        }
        return rect
    }

}
