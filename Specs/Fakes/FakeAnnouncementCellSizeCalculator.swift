////
///  FakeAnnouncementCellSizeCalculator.swift
//

@testable
import Ello
import Foundation


open class FakeAnnouncementCellSizeCalculator: AnnouncementCellSizeCalculator {

    override open func processCells(_ cellItems: [StreamCellItem], withWidth: CGFloat, completion: @escaping ElloEmptyCompletion) {
        for item in cellItems {
            item.calculatedCellHeights.oneColumn = AppSetup.Size.calculatorHeight
            item.calculatedCellHeights.multiColumn = AppSetup.Size.calculatorHeight
        }
        completion()
    }
}
