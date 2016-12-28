////
///  ElloTextFieldView.swift
//

import Foundation

private let ElloTextFieldViewHeight: CGFloat = 89.0

open class ElloTextFieldView: UIView {
    open weak var label: StyledLabel!
    @IBOutlet open weak var textField: ElloTextField!
    open weak var errorLabel: StyledLabel!
    open weak var messageLabel: StyledLabel!

    @IBOutlet fileprivate var errorLabelHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var messageLabelHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var errorLabelSeparationSpacing: NSLayoutConstraint!

    open var textFieldDidChange: ((String) -> Void)?
    open var firstResponderDidChange: ((Bool) -> Void)? {
        get { return textField.firstResponderDidChange }
        set { textField.firstResponderDidChange = newValue }
    }

    var height: CGFloat {
        var height = ElloTextFieldViewHeight
        if hasError {
            height += errorHeight
            if hasMessage {
                height += 20
            }
            else {
                height += 8
            }
        }
        if hasMessage {
            height += messageHeight + 8
        }
        return height
    }

    open var hasError: Bool { return !(errorLabel.text?.isEmpty ?? true) }
    open var hasMessage: Bool { return !(messageLabel.text?.isEmpty ?? true) }
    var errorHeight: CGFloat {
        if hasError {
            return errorLabel.sizeThatFits(CGSize(width: errorLabel.frame.width, height: 0)).height
        }
        else {
            return 0
        }
    }
    var messageHeight: CGFloat {
        if hasMessage {
            return messageLabel.sizeThatFits(CGSize(width: messageLabel.frame.width, height: 0)).height
        }
        else {
            return 0
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    fileprivate func sharedInit() {
        let view: UIView = loadFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(view)

        textField.addTarget(self, action: #selector(valueChanged), for: .editingChanged)
    }

    override open func updateConstraints() {
        updateErrorConstraints()
        super.updateConstraints()
    }

    func setState(_ state: ValidationState) {
        textField.validationState = state
    }

    func valueChanged() {
        setNeedsUpdateConstraints()
        if let textFieldDidChange = textFieldDidChange, let text = textField.text {
            textFieldDidChange(text)
        }
    }

    func setErrorMessage(_ message: String) {
        errorLabel.text = message
        setNeedsUpdateConstraints()
        self.invalidateIntrinsicContentSize()
    }

    func setMessage(_ message: String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.black
        setNeedsUpdateConstraints()
        self.invalidateIntrinsicContentSize()
    }

    override open func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.label.layoutIfNeeded()
        self.textField.layoutIfNeeded()
        self.messageLabel.layoutIfNeeded()
        self.errorLabel.layoutIfNeeded()
    }

    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: height)
    }

    fileprivate func updateErrorConstraints() {
        errorLabelSeparationSpacing.isActive = errorHeight > 0 && messageHeight > 0
        errorLabelHeight.constant = errorHeight
        messageLabelHeight.constant = messageHeight
    }

    func clearState() {
        textField.validationState = .none
        setErrorMessage("")
        setMessage("")
    }

    override open func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override open func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

}


public extension ElloTextFieldView {
    fileprivate class func styleCommonField(_ textField: UITextField) {
        textField.text = ""
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.enablesReturnKeyAutomatically = true
        textField.keyboardAppearance = .dark
    }

    class func styleAsUsername(_ usernameView: ElloTextFieldView) {
        usernameView.label.text = InterfaceString.Join.Username
        styleAsUsernameField(usernameView.textField)
    }
    class func styleAsUsernameField(_ textField: UITextField) {
        styleCommonField(textField)
        textField.returnKeyType = .next
        textField.keyboardType = .asciiCapable
    }

    class func styleAsEmail(_ emailView: ElloTextFieldView) {
        emailView.label.text = InterfaceString.Join.Email
        styleAsEmailField(emailView.textField)
    }
    class func styleAsEmailField(_ textField: UITextField) {
        styleCommonField(textField)
        textField.returnKeyType = .next
        textField.keyboardType = .emailAddress
    }

    class func styleAsPassword(_ passwordView: ElloTextFieldView) {
        passwordView.label.text = InterfaceString.Join.Password
        styleAsPasswordField(passwordView.textField)
    }
    class func styleAsPasswordField(_ textField: UITextField) {
        styleCommonField(textField)
        textField.returnKeyType = .go
        textField.keyboardType = .default
        textField.isSecureTextEntry = true
    }

}
