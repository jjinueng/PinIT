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
    
    @objc func toggleFavorite(sender: UIButton) {
        guard let cell = sender.superview as? LocationCell,
              let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        locations[indexPath.row].isFavorite.toggle()
        collectionView.reloadItems(at: [indexPath])
        saveFavoriteLocations()
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
        cell.favoriteButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.toggleFavorite(at: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let location = locations[indexPath.item]
        showDetailPopup(for: location, at: indexPath)
    }

    func showDetailPopup(for location: Location, at indexPath: IndexPath) {
        let detailVC = DetailPopupViewController()
        detailVC.location = location
        detailVC.indexPath = indexPath
        detailVC.onSave = { [weak self] updatedLocation, indexPath in
            guard let self = self else { return }
            self.locations[indexPath.item] = updatedLocation
            self.saveFavoriteLocations()  // 변경된 데이터 저장
            self.collectionView.reloadItems(at: [indexPath])
        }
        present(detailVC, animated: true, completion: nil)
    }

    
    func saveLocationDetails() {
        let data = locations.map {
            [
                "latitude": $0.latitude,
                "longitude": $0.longitude,
                "isFavorite": $0.isFavorite,
                "buildingName": $0.buildingName,
                "fullAddress": $0.fullAddress,
                "createdAt": $0.createdAt,
                "nickname": $0.nickname,
                "memo": $0.memo,
                "category": $0.category
            ] as [String : Any]
        }
        UserDefaults.standard.set(data, forKey: "savedMarkerLocations")
    }

    
    func loadVisitedPlaces() {
        let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        let reversedLocations = Array(savedLocations.reversed())
        
        locations = reversedLocations.map { dict in
            let imageDataArray = dict["images"] as? [Data] ?? []
            let images = imageDataArray.compactMap { UIImage(data: $0) }
            
            return Location(
                latitude: dict["latitude"] as? Double ?? 0.0,
                longitude: dict["longitude"] as? Double ?? 0.0,
                buildingName: dict["buildingName"] as? String ?? "",
                fullAddress: dict["fullAddress"] as? String ?? "",
                createdAt: Date(timeIntervalSince1970: dict["createdAt"] as? TimeInterval ?? 0),
                isFavorite: dict["isFavorite"] as? Bool ?? false,
                nickname: dict["nickname"] as? String ?? "",
                memo: dict["memo"] as? String ?? "",
                category: dict["category"] as? String ?? "",
                categoryColor: UIColor(hex: dict["categoryColor"] as? String ?? "#FFFFFF"),
                images: images
            )
        }
        loadFavoriteLocations() // Ensure favorite states are loaded
    }


    func toggleFavorite(at indexPath: IndexPath) {
        locations[indexPath.row].isFavorite.toggle()
        collectionView.reloadItems(at: [indexPath])
        saveFavoriteLocations()
    }

    func saveFavoriteLocations() {
        let favorites = locations.filter { $0.isFavorite }
        let data = favorites.map { location -> [String: Any] in
            var dict: [String: Any] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "isFavorite": location.isFavorite,
                "buildingName": location.buildingName,
                "fullAddress": location.fullAddress,
                "createdAt": location.createdAt.timeIntervalSince1970,
                "nickname": location.nickname ?? "",
                "memo": location.memo ?? "",
                "category": location.category ?? "",
                "categoryColor": location.categoryColor?.hexString ?? "#FFFFFF"
            ]
            let imageData = location.images.compactMap { $0.jpegData(compressionQuality: 1.0) }
            dict["images"] = imageData
            return dict
        }
        UserDefaults.standard.set(data, forKey: "FavoriteLocations")
        UserDefaults.standard.synchronize()
    }
    
    func loadFavoriteLocations() {
        guard let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteLocations") as? [[String: Any]] else { return }
        for (index, location) in locations.enumerated() {
            if savedFavorites.contains(where: {
                guard let lat = $0["latitude"] as? Double, let lng = $0["longitude"] as? Double else { return false }
                return lat == location.latitude && lng == location.longitude
            }) {
                locations[index].isFavorite = true
            }
        }
        collectionView.reloadData()
    }

}

class LocationCell: UICollectionViewCell {
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var imageView: UIImageView!
    var favoriteButton: UIButton!
    
    var favoriteButtonTapped: (() -> Void)?
    
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
        

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // contentView에 요소 추가
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(imageView)
        
        favoriteButton = UIButton(type: .system)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(favoriteButton)
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.tintColor = .white
        
        
        
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
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),
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
        favoriteButton.setImage(UIImage(systemName: location.isFavorite ? "heart.fill" : "heart"), for: .normal)
        favoriteButton.tintColor = location.isFavorite ? .red : .white
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
    }
    
    @objc func toggleFavorite() {
        favoriteButtonTapped?()
    }
    
}

