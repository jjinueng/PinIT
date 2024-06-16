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
    var buildingName: String?
    var fullAddress: String?
    var createdAt: Date
    var isFavorite: Bool
    var nickname: String?
    var memo: String?
    var category: String?
    var categoryColor: UIColor?
    var images: [UIImage]
    
    var region: String {
        guard let fullAddress = fullAddress else { return "알 수 없음" }
        
        let regionMapping: [String: String] = [
            "서울특별시": "서울",
            "인천광역시": "인천",
            "강원도": "강원",
            "충청남도": "충남",
            "충청북도": "충북",
            "경상북도": "경북",
            "경상남도": "경남",
            "전라북도": "전북",
            "전라남도": "전남",
            "세종특별자치시": "세종",
            "대전광역시": "대전",
            "대구광역시": "대구",
            "울산광역시": "울산",
            "부산광역시": "부산",
            "제주특별자치도": "제주"
        ]
        
        for (fullName, shortName) in regionMapping {
            if fullAddress.contains(fullName) {
                return shortName
            }
        }
        return "알 수 없음"
    }
}
