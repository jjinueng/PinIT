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
    var recommendedPlaces: [String] = []
    var visitedCollectionView: UICollectionView!
    var recommendedCollectionView: UICollectionView!
    var searchBar: UISearchBar!
    var recentPlacesLabel: UILabel!
    var recommendedPlacesLabel: UILabel!
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupSearchBar()
        setupRecentPlacesLabel()
        setupVisitedCollectionView()
        setupRecommendedPlacesLabel()
        setupRecommendedCollectionView()
        setupLocationManager()
        loadVisitedPlaces()
        NotificationCenter.default.addObserver(self, selector: #selector(locationsDidUpdate), name: .didSaveLocation, object: nil)
    }
    
    @objc func locationsDidUpdate(notification: Notification) {
        loadVisitedPlaces()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadVisitedPlaces() {
        let savedLocations = LocationManager.shared.loadLocations()
        visitedLocations = savedLocations.map { CLLocation(latitude: $0["latitude"]!, longitude: $0["longitude"]!) }
        visitedLocations.forEach { reverseGeocodeLocation(location: $0) }
    }
    
    func saveLocation(location: CLLocation) {
        let locationData = ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
        LocationManager.shared.saveLocations(locations: [locationData])
        NotificationCenter.default.post(name: .didSaveLocation, object: nil)
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "장소 검색"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchBar)
        
        // 검색 바 스타일링
        if let searchTextField = searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = UIColor.systemGray6
            searchTextField.layer.cornerRadius = 15
            searchTextField.layer.masksToBounds = true
            searchTextField.borderStyle = .none
        }
        
        // 검색 바 밑줄 제거
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 10, vertical: 0)
        
        // 검색 바 제약 조건 설정
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func setupRecentPlacesLabel() {
        recentPlacesLabel = UILabel()
        recentPlacesLabel.text = "최근 방문한 장소"
        recentPlacesLabel.font = UIFont.boldSystemFont(ofSize: 18)
        recentPlacesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recentPlacesLabel)
        
        // 최근 방문한 장소 레이블 제약 조건 설정
        NSLayoutConstraint.activate([
            recentPlacesLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            recentPlacesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
    }
    
    func setupVisitedCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 200, height: 150)
        
        visitedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        visitedCollectionView.delegate = self
        visitedCollectionView.dataSource = self
        visitedCollectionView.register(VisitedPlaceCell.self, forCellWithReuseIdentifier: "VisitedPlaceCell")
        visitedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        visitedCollectionView.backgroundColor = .white
        contentView.addSubview(visitedCollectionView)
        
        // 컬렉션 뷰 제약 조건 설정
        NSLayoutConstraint.activate([
            visitedCollectionView.topAnchor.constraint(equalTo: recentPlacesLabel.bottomAnchor, constant: 10),
            visitedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            visitedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            visitedCollectionView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    func setupRecommendedPlacesLabel() {
        recommendedPlacesLabel = UILabel()
        recommendedPlacesLabel.text = "추천 장소"
        recommendedPlacesLabel.font = UIFont.boldSystemFont(ofSize: 18)
        recommendedPlacesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendedPlacesLabel)
        
        // 추천 장소 레이블 제약 조건 설정
        NSLayoutConstraint.activate([
            recommendedPlacesLabel.topAnchor.constraint(equalTo: visitedCollectionView.bottomAnchor, constant: 10),
            recommendedPlacesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
    }
    
    func setupRecommendedCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 200, height: 150)
        
        recommendedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        recommendedCollectionView.delegate = self
        recommendedCollectionView.dataSource = self
        recommendedCollectionView.register(VisitedPlaceCell.self, forCellWithReuseIdentifier: "VisitedPlaceCell")
        recommendedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        recommendedCollectionView.backgroundColor = .white
        contentView.addSubview(recommendedCollectionView)
        
        // 컬렉션 뷰 제약 조건 설정
        NSLayoutConstraint.activate([
            recommendedCollectionView.topAnchor.constraint(equalTo: recommendedPlacesLabel.bottomAnchor, constant: 10),
            recommendedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recommendedCollectionView.heightAnchor.constraint(equalToConstant: 150),
            recommendedCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == visitedCollectionView {
            return min(filteredAddresses.count, 5)
        } else {
            return recommendedPlaces.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VisitedPlaceCell", for: indexPath) as! VisitedPlaceCell
        if collectionView == visitedCollectionView {
            let address = filteredAddresses[indexPath.row]
            cell.configure(with: address)
        } else {
            let place = recommendedPlaces[indexPath.row]
            cell.configure(with: place)
        }
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
            generateRecommendedPlaces(from: currentLocation)
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
                        strongSelf.visitedCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func generateRecommendedPlaces(from location: CLLocation) {
        recommendedPlaces.removeAll()
        
        for _ in 1...5 {
            let randomLat = location.coordinate.latitude + Double(arc4random_uniform(100)) / 10000.0
            let randomLng = location.coordinate.longitude + Double(arc4random_uniform(100)) / 10000.0
            let newLocation = CLLocation(latitude: randomLat, longitude: randomLng)
            reverseGeocodeRecommendedLocation(location: newLocation)
        }
    }
    
    
    func reverseGeocodeRecommendedLocation(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let strongSelf = self else { return }
            if let placemarks = placemarks, let placemark = placemarks.first {
                if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    var fullAddress = addrList.joined(separator: ", ")
                    if fullAddress.hasPrefix("대한민국") {
                        fullAddress = String(fullAddress.dropFirst("대한민국".count)).trimmingCharacters(in: .whitespaces)
                    }
                    let placeWithAddress = "\(fullAddress)"
                    strongSelf.recommendedPlaces.append(placeWithAddress)
                    DispatchQueue.main.async {
                        strongSelf.recommendedCollectionView.reloadData()
                    }
                }
            }
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
