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
        
        self.selectedIndex = 1
        tabBar.tintColor = UIColor(hex: "#CE3B3D")
        
        if let items = tabBar.items {
            items[0].image = UIImage(named: "map")
            items[0].selectedImage = UIImage(named: "map_fill")
            

            items[1].image = UIImage(named: "home")
            items[1].selectedImage = UIImage(named: "home_fill")
            

            items[2].image = UIImage(named: "pinmap")
            items[2].selectedImage = UIImage(named: "pinmap_fill")
        }
    }
}

