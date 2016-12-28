////
///  OnePasswordButton.swift
//

open class OnePasswordButton: UIButton {

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedSetup()
    }

    func sharedSetup() {
        setImage(.onePassword, imageStyle: .white, for: .normal)
        contentMode = .center
    }

}
