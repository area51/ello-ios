////
///  AutoCompleteDataSource.swift
//

public struct AutoCompleteItem {
    public let result: AutoCompleteResult
    public let type: AutoCompleteType
    public let match: AutoCompleteMatch

    public init(result: AutoCompleteResult, type: AutoCompleteType, match: AutoCompleteMatch) {
        self.result = result
        self.type = type
        self.match = match
    }
}

open class AutoCompleteDataSource: NSObject {
    open var items: [AutoCompleteItem] = []

    open func itemForIndexPath(_ indexPath: IndexPath) -> AutoCompleteItem? {
        return items.safeValue(indexPath.row)
    }
}

// MARK: UITableViewDataSource
extension AutoCompleteDataSource: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AutoCompleteCell.reuseIdentifier, for: indexPath) as! AutoCompleteCell
        if let item = items.safeValue(indexPath.row) {
            AutoCompleteCellPresenter.configure(cell, item: item)
        }
        return cell
    }
}
