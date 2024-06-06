//
//  LaunchViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/7/24.
//
import UIKit

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 배경색 설정
        view.backgroundColor = UIColor(hex: "#CE3B3D")
        
        // 이미지 뷰 추가
        let imageView = UIImageView(image: UIImage(named: "pinmap"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        view.addSubview(imageView)
        
        // 이미지 뷰 제약조건 설정
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // 환영 메시지 레이블 추가
        let label = UILabel()
        label.text = "Welcome to My App!"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // 레이블 제약조건 설정
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20)
        ])
        
        // 화면에 나타나는 시간 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // 다음 화면으로 이동
            self.showNextViewController()
        }
    }
    
    // 다음 화면으로 이동하는 메서드
    private func showNextViewController() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mainViewController = mainStoryboard.instantiateViewController(withIdentifier: "YourMainViewControllerIdentifier") as? HomeViewController else {
            fatalError("Unable to instantiate YourMainViewController")
        }
        UIApplication.shared.windows.first?.rootViewController = mainViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

}
