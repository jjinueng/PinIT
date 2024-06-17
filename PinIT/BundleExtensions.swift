//
//  BundleExtensions.swift
//  PinIT
//
//  Created by 김지윤 on 6/6/24.
//

import Foundation

extension Bundle {
    
    var NAVER_MAP_API_KEY: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["NAVER_MAP_API_KEY"] as? String else {
            fatalError("NAVER_MAP_API_KEY error")
        }
        return key
    }
    
    var NAVER_MAP_API_KEY_ID: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["NAVER_MAP_API_KEY_ID"] as? String else {
            fatalError("NAVER_MAP_API_KEY_ID error")
        }
        return key
    }
    
    var GOOGLE_MAP_API_KEY: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["GOOGLE_MAP_API_KEY"] as? String else {
            fatalError("GOOGLE_MAP_API_KEY error")
        }
        return key
    }
    
    var NAVER_SEARCH_API_KEY_ID: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["NAVER_SEARCH_API_KEY_ID"] as? String else {
            fatalError("NAVER_SEARCH_API_KEY_ID error")
        }
        return key
    }
    
    var NAVER_SEARCH_API_KEY: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["NAVER_SEARCH_API_KEY"] as? String else {
            fatalError("NAVER_SEARCH_API_KEY error")
        }
        return key
    }
}
