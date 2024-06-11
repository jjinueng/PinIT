//
//  Model.swift
//  PinIT
//
//  Created by 김지윤 on 6/7/24.
//

import UIKit
import CoreLocation

struct Location {
    var latitude: Double
    var longitude: Double
    var buildingName: String
    var fullAddress: String
    var createdAt: Date
    var isFavorite: Bool
    var nickname: String?
    var memo: String?
    var category: String?
    var categoryColor: UIColor?
    var images: [UIImage]
}
