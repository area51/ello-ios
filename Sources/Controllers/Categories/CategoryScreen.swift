////
///  CategoryScreen.swift
//

import SnapKit


open class CategoryScreen: StreamableScreen, CategoryScreenProtocol {
    weak var delegate: CategoryScreenDelegate?

    fileprivate let categoryCardList = CategoryCardListView()

    open var topInsetView: UIView {
        if categoryCardList.isHidden {
            return navigationBar
        }
        else {
            return categoryCardList
        }
    }

    open var categoryCardsVisible: Bool {
        return !categoryCardList.isHidden
    }

    override func bindActions() {
        super.bindActions()
        categoryCardList.delegate = self
    }

    override func arrange() {
        super.arrange()
        addSubview(categoryCardList)
        addSubview(navigationBar)
        categoryCardList.isHidden = true

        categoryCardList.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalTo(self)
            make.height.equalTo(CategoryCardListView.Size.height)
        }
    }

    open func set(categoriesInfo newValue: [CategoryCardListView.CategoryInfo], animated: Bool, completion: @escaping ElloEmptyCompletion) {
        categoryCardList.isHidden = newValue.isEmpty
        categoryCardList.categoriesInfo = newValue

        if !categoryCardList.isHidden && animated {
            let originalY = categoryCardList.frame.origin.y
            categoryCardList.frame.origin.y = -categoryCardList.frame.size.height
            animate(completion: { _ in completion() }) {
                self.categoryCardList.frame.origin.y = originalY
            }
        }
        else {
            completion()
        }
    }

    open func animateCategoriesList(navBarVisible: Bool) {
        animate {
            if navBarVisible {
                self.categoryCardList.frame.origin.y = self.navigationBar.frame.height
            }
            else {
                self.categoryCardList.frame.origin.y = 0
            }
        }
    }

    open func scrollToCategory(index: Int) {
        self.categoryCardList.scrollToIndex(index, animated: false)
    }

    open func selectCategory(index: Int) {
        self.categoryCardList.selectCategoryIndex(index)
    }
}

extension CategoryScreen: CategoryCardListDelegate {
    public func categoryCardSelected(_ index: Int) {
        delegate?.categorySelected(index: index)
    }
}
