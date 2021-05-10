//
//  WalkDataTableViewSection.swift
//  SmoothWalker
//
//  Created by Yangbin Wen on 5/8/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

enum WalkDataTableViewCellType: String {
    case normalCell

    var identifier: String {
        switch self {
        case .normalCell:
            return "normalCell"
        }
    }
}

struct WalkDataTableCellModel {
    let cellType: WalkDataTableViewCellType
    let startDate: String
    let endDate: String
    let speed: Double
}

struct WalkDataTableViewSection {
    let id: String
    var items: [WalkDataTableCellModel]
}

extension WalkDataTableViewSection: SectionModelType {
    typealias Item = WalkDataTableCellModel
    init(original: WalkDataTableViewSection, items: [Item]) {
        self = original
        self.items = items
    }

    init(id _: String? = UUID().uuidString, original: WalkDataTableViewSection, items: [Item]) {
        self = original
        self.items = items
    }
}
