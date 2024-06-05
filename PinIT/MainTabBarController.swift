//
//  MainTabBarController.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 기본 선택된 인덱스를 가운데 탭으로 설정
        self.selectedIndex = 1 // 가운데에 있는 탭의 인덱스
    }
}
