//
//  Models.swift
//  Fundra
//
//  Created by Brian Janish on 6/10/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var balances: [Balance]
    
    init(name: String, sortOrder: Int) {
        self.name = name
        self.sortOrder = sortOrder
        self.balances = []
    }
}

@Model
final class Balance {
    var category: Category?
    var year: Int
    var month: Int
    var day: Int
    var amount: Double
    var updatedAt: Date?
    
    init(category: Category, year: Int, month: Int, day: Int, amount: Double) {
        self.category = category
        self.year = year
        self.month = month
        self.day = day
        self.amount = amount
        self.updatedAt = Date()
    }
}
