////
///  SearchTextField.swift
//

open class SearchTextField: UITextField {
    override open var placeholder: String? {
        didSet {
            if let placeholder = placeholder {
                attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [
                        NSForegroundColorAttributeName: UIColor.greyA()
                    ])
            }
        }
    }
    fileprivate var line = UIView()

    override required public init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    fileprivate func sharedInit() {
        clearButtonMode = .whileEditing
        font = .defaultFont(18)
        textColor = .black
        autocapitalizationType = .none
        autocorrectionType = .no
        spellCheckingType = .no
        enablesReturnKeyAutomatically = true
        returnKeyType = .search
        keyboardAppearance = .dark
        keyboardType = .default
        leftViewMode = .always
        leftView = UIImageView(image: InterfaceImage.search.normalImage)

        addSubview(line)
        line.backgroundColor = .greyA()
        line.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self).offset(-10)
            make.height.equalTo(1)
        }
    }

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return rectForBounds(bounds)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return rectForBounds(bounds)
    }

    fileprivate func rectForBounds(_ bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.shrink(right: 10)
    }
}
