//
//  HomeViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/5/24.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    var locationManager: CLLocationManager!
    var visitedLocations: [CLLocation] = []
    var visitedAddresses: [String] = []
    var filteredAddresses: [String] = []
    var recommendedPlaces: [String] = ["Place A", "Place B", "Place C"]
    var collectionView: UICollectionView!
    var searchBar: UISearchBar!
    var recentPlacesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupRecentPlacesLabel()
        setupCollectionView()
        setupLocationManager()
        loadVisitedPlaces()
    }
    
    func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search address"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // 검색 바 제약 조건 설정
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setupRecentPlacesLabel() {
        recentPlacesLabel = UILabel()
        recentPlacesLabel.text = "최근 방문한 장소"
        recentPlacesLabel.font = UIFont.boldSystemFont(ofSize: 18)
        recentPlacesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recentPlacesLabel)
        
        // 최근 방문한 장소 레이블 제약 조건 설정
        NSLayoutConstraint.activate([
            recentPlacesLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            recentPlacesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 200, height: 150)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VisitedPlaceCell.self, forCellWithReuseIdentifier: "VisitedPlaceCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        // 컬렉션 뷰 제약 조건 설정
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: recentPlacesLabel.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(filteredAddresses.count, 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VisitedPlaceCell", for: indexPath) as! VisitedPlaceCell
        let address = filteredAddresses[indexPath.row]
        cell.configure(with: address)
        return cell
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
            reverseGeocodeLocation(location: currentLocation)
            visitedLocations.insert(currentLocation, at: 0) // 최근 위치를 맨 앞에 추가
        }
    }
    
    func reverseGeocodeLocation(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let strongSelf = self else { return }
            if let placemarks = placemarks, let placemark = placemarks.first {
                if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    var fullAddress = addrList.joined(separator: ", ")
                    if fullAddress.hasPrefix("대한민국") {
                        fullAddress = String(fullAddress.dropFirst("대한민국".count)).trimmingCharacters(in: .whitespaces)
                    }
                    strongSelf.visitedAddresses.insert(fullAddress, at: 0) // 최근 주소를 맨 앞에 추가
                    strongSelf.filteredAddresses = strongSelf.visitedAddresses
                    DispatchQueue.main.async {
                        strongSelf.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func loadVisitedPlaces() {
        if let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Double]] {
            visitedLocations = savedLocations.map { CLLocation(latitude: $0["latitude"]!, longitude: $0["longitude"]!) }
            visitedLocations.forEach { reverseGeocodeLocation(location: $0) }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    // UISearchBarDelegate 메서드 추가
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredAddresses = visitedAddresses
        } else {
            filteredAddresses = visitedAddresses.filter { $0.contains(searchText) }
        }
        collectionView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredAddresses = visitedAddresses
        collectionView.reloadData()
    }
}

class VisitedPlaceCell: UICollectionViewCell {
    var addressLabel: UILabel!
    var containerView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        containerView = UIView()
        containerView.backgroundColor = UIColor.systemGray6
        containerView.layer.cornerRadius = 15
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        containerView.layer.shadowRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.numberOfLines = 0
        addressLabel.textAlignment = .center
        addressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        containerView.addSubview(addressLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with address: String) {
        addressLabel.text = address
    }
}
