//
//  CategoryManager.swift
//  PinIT
//
//  Created by 김지윤 on 6/11/24.
//

import Foundation
import UIKit

class CategoryManager {
    static let shared = CategoryManager()
    
    private let userDefaultsKey = "CustomCategories"
    private var categories: [(name: String, color: UIColor)] = []
    
    private init() {
        loadCategories()
    }
    
    func addCategory(name: String, color: UIColor) {
        categories.append((name, color))
        saveCategories()
    }
    
    func getCategories() -> [(name: String, color: UIColor)] {
        return categories
    }
    
    private func saveCategories() {
        let data = categories.map { ["name": $0.name, "color": $0.color.hexString] }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    private func loadCategories() {
        guard let data = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String: String]] else { return }
        categories = data.map { (name: $0["name"] ?? "", color: UIColor(hex: $0["color"] ?? "#FFFFFF")) }
    }
}
