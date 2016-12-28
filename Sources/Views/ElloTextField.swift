////
///  ElloTextField.swift
//

open class ElloTextField: UITextField {
    open var firstResponderDidChange: ((Bool) -> Void)?
    var hasOnePassword = false
    var validationState = ValidationState.none {
        didSet {
            self.rightViewMode = .always
            self.rightView = UIImageView(image: validationState.imageRepresentation)
        }
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedSetup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.sharedSetup()
    }

    func sharedSetup() {
        self.backgroundColor = UIColor.greyE5()
        self.font = UIFont.defaultFont()
        self.textColor = UIColor.black

        self.setNeedsDisplay()
    }

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
        return rect
    }

    override open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.origin.x += 11
        return rect
    }

    fileprivate func rectForBounds(_ bounds: CGRect) -> CGRect {
        var rect = bounds.shrink(left: 15).inset(topBottom: 10, sides: 15)
        if let leftView = leftView {
            rect = rect.shrink(right: leftView.frame.size.width + 6)
        }
        return rect
    }

    override open func becomeFirstResponder() -> Bool {
        let val = super.becomeFirstResponder()
        firstResponderDidChange?(true)
        return val
    }

    override open func resignFirstResponder() -> Bool {
        let val = super.resignFirstResponder()
        firstResponderDidChange?(false)
        return val
    }

}
