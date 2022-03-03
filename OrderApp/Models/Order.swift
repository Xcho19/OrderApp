//
//  Order.swift
//  OrderApp
//
//  Created by Xcho on 28.02.22.
//

import Foundation

struct Order: Codable {
    var menuItems: [MenuItem]

    init(menuItems: [MenuItem] = []) {
        self.menuItems = menuItems
    }
}
