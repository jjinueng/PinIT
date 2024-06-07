//
//  ListViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit
import CoreLocation

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var locations: [Location] = []
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadVisitedPlaces()
        NotificationCenter.default.addObserver(self, selector: #selector(locationsDidUpdate), name: .didSaveLocation, object: nil)
    }
    
    @objc func locationsDidUpdate(notification: Notification) {
        loadVisitedPlaces()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.size.width / 2 - 15, height: 200)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: "LocationCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LocationCell", for: indexPath) as? LocationCell else {
            fatalError("Unable to dequeue LocationCell")
        }
        let location = locations[indexPath.item]
        cell.configure(with: location)
        return cell
    }

    func loadVisitedPlaces() {
        let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        let reversedLocations = Array(savedLocations.reversed())

        locations = reversedLocations.map { dict in
            Location(
                latitude: dict["latitude"] as? Double ?? 0.0,
                longitude: dict["longitude"] as? Double ?? 0.0,
                buildingName: dict["buildingName"] as? String ?? "",
                fullAddress: dict["fullAddress"] as? String ?? "",
                createdAt: dict["createdAt"] as? Date ?? Date(),
                streetViewImage: nil  // 이미지는 초기에 nil로 설정
            )
        }
        
//        for (index, location) in locations.enumerated() {
//            fetchStreetViewImage(for: CLLocation(latitude: location.latitude, longitude: location.longitude)) { [weak self] image in
//                guard let self = self else { return }
//                self.locations[index].streetRoleImage = image
//                DispatchQueue.main.async {
//                    self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
//                }
//            }
//        }
    }
}

class LocationCell: UICollectionViewCell {
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        applyStyling()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        imageView = UIImageView()

        // Auto Layout 사용 설정
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // contentView에 요소 추가
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(imageView)

        // 제약 조건 추가
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            imageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 5),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    private func applyStyling() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowColor = UIColor.black.cgColor

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.numberOfLines = 0

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    func configure(with location: Location) {
        titleLabel.text = location.buildingName
        subtitleLabel.text = location.fullAddress
        imageView.image = location.streetViewImage
    }
}
