////
///  DynamicSettingCell.swift
//

public protocol DynamicSettingCellDelegate: class {
    func toggleSetting(_ setting: DynamicSetting, value: Bool)
    func deleteAccount()
}

open class DynamicSettingCell: UITableViewCell {
    @IBOutlet open weak var titleLabel: StyledLabel!
    open weak var descriptionLabel: StyledLabel!
    @IBOutlet open weak var toggleButton: ElloToggleButton!
    @IBOutlet open weak var deleteButton: ElloToggleButton!

    open weak var delegate: DynamicSettingCellDelegate?
    open var setting: DynamicSetting?

    @IBAction open func toggleButtonTapped() {
        if let setting = setting {
            delegate?.toggleSetting(setting, value: !toggleButton.value)
            toggleButton.value = !toggleButton.value
        }
    }

    @IBAction open func deleteButtonTapped() {
        delegate?.deleteAccount()
    }
}
