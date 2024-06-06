//
//  HomeViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/5/24.
//
import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class HomeViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    var locationManager: CLLocationManager!
    var visitedLocations: [CLLocation] = []
    var visitedAddresses: [(String, String, UIImage?)] = []
    var filteredAddresses: [(String, String, UIImage?)] = []
    var recommendedPlaces: [(String, UIImage?)] = []
    
    var visitedCollectionView: UICollectionView!
    var recommendedCollectionView: UICollectionView!
    var searchBar: UISearchBar!
    var recentPlacesLabel: UILabel!
    var recommendedPlacesLabel: UILabel!
    var scrollView: UIScrollView!
    var contentView: UIView!
    var tableView: UITableView!
    var tableViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupSearchBar()
        setupTableView()
        setupRecentPlacesLabel()
        setupVisitedCollectionView()
        setupRecommendedPlacesLabel()
        setupRecommendedCollectionView()
        setupLocationManager()
        loadVisitedPlaces()
        NotificationCenter.default.addObserver(self, selector: #selector(locationsDidUpdate), name: .didSaveLocation, object: nil)
        contentView.bringSubviewToFront(tableView)
    }
    
    @objc func locationsDidUpdate(notification: Notification) {
        loadVisitedPlaces()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }

    
    func loadVisitedPlaces() {
        let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []

        // savedLocations를 역순으로 정렬
        let reversedLocations = Array(savedLocations.reversed())

        visitedLocations = reversedLocations.map { dict in
            CLLocation(latitude: dict["latitude"] as! Double, longitude: dict["longitude"] as! Double)
        }
        visitedAddresses = Array(repeating: ("", "", nil), count: reversedLocations.count)  // 순서 보장을 위해 초기화
        
        for (index, location) in visitedLocations.enumerated() {
            let buildingName = reversedLocations[index]["buildingName"] as? String ?? ""
            let fullAddress = reversedLocations[index]["fullAddress"] as? String ?? ""
            let address = fullAddress  // 필요한 경우 address로 검색 가능하도록 fullAddress를 address로 사용

            fetchStreetViewImage(for: location) { [weak self] image in
                guard let self = self else { return }
                self.visitedAddresses[index] = (address, buildingName, image)  // 인덱스를 사용하여 올바른 위치에 삽입
                DispatchQueue.main.async {
                    self.filteredAddresses = self.visitedAddresses
                    self.visitedCollectionView.reloadData()
                    self.tableView.reloadData()
                    print(buildingName)
                }
            }
        }
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
        searchBar.placeholder = "방문한 장소 검색"
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
    
    func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        
        // 테이블 뷰 셀 등록
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddressCell")
        
        // 테이블 뷰 제약 조건 설정
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            // tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor) // 기존 bottom 제약 조건 제거
        ])
        
        // 테이블 뷰 높이 제약 조건 추가
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint.isActive = true
        
        // 초기에는 테이블 뷰를 숨김
        tableView.isHidden = true
        
        // 테이블 뷰 contentSize 관찰
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            tableViewHeightConstraint.constant = tableView.contentSize.height
        }
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
        layout.itemSize = CGSize(width: 200, height: 200) // 이미지 높이에 맞게 크기 조정
        
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
            visitedCollectionView.heightAnchor.constraint(equalToConstant: 200) // 이미지 높이에 맞게 크기 조정
        ])
    }
    
    func setupRecommendedPlacesLabel() {
        recommendedPlacesLabel = UILabel()
        recommendedPlacesLabel.text = "이 장소는 어때요?"
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
        layout.itemSize = CGSize(width: 200, height: 200) // 이미지 높이에 맞게 크기 조정
        
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
            recommendedCollectionView.heightAnchor.constraint(equalToConstant: 200), // 이미지 높이에 맞게 크기 조정
            recommendedCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == visitedCollectionView {
            return min(filteredAddresses.count, 5) // 최대 5개만 표시
        } else {
            return recommendedPlaces.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VisitedPlaceCell", for: indexPath) as! VisitedPlaceCell
        if collectionView == visitedCollectionView {
            let addressTuple = filteredAddresses[indexPath.row]
            let displayText = addressTuple.1.isEmpty ? addressTuple.0 : "\(addressTuple.1)\n\(addressTuple.0)"
            cell.configure(with: displayText, image: addressTuple.2)
        } else {
            let place = recommendedPlaces[indexPath.row]
            cell.configure(with: place.0, image: place.1)
        }
        cell.backgroundColor = .white
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
            generateRecommendedPlaces(from: currentLocation)
        }
    }
    
    func reverseGeocodeLocation(location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks, let placemark = placemarks.first {
                var address: String = placemark.name!
                if let subThoroughfare = placemark.thoroughfare, let name = placemark.name, name.contains(subThoroughfare) {
                    if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                        address  = addrList.joined(separator: ", ")
                        
                        // "대한민국" 문자열을 제거합니다.
                        if address.hasPrefix("대한민국") {
                            address = String(address.dropFirst("대한민국".count)).trimmingCharacters(in: .whitespaces)
                        } else if let commaIndex = address.firstIndex(of: ",") {
                            // "대한민국"으로 시작하지 않으면 첫 번째 콤마가 나올 때까지 삭제합니다.
                            address = String(address[commaIndex...]).trimmingCharacters(in: .whitespaces)
                            address = String(address.dropFirst(", 대한민국".count)).trimmingCharacters(in: .whitespaces)
                        }
                        // 쉼표를 찾고 첫 번째 쉼표 이후의 문자를 제거합니다.
                        if let commaIndex = address.firstIndex(of: ",") {
                            address = String(address[..<commaIndex])
                        }
                    }
                }
                completion(address)
            } else {
                completion("No Address")
            }
        }
    }
    
    func generateRecommendedPlaces(from location: CLLocation) {
        recommendedPlaces.removeAll()
        
        for _ in 1...5 {
            let randomLat = location.coordinate.latitude + Double(arc4random_uniform(100)) / 10000.0
            let randomLng = location.coordinate.longitude + Double(arc4random_uniform(100)) / 10000.0
            let newLocation = CLLocation(latitude: randomLat, longitude: randomLng)
            reverseGeocodeLocation(location: newLocation) { [weak self] address in
                guard let self = self else { return }
                self.fetchStreetViewImage(for: newLocation) { image in
                    self.recommendedPlaces.append((address, image))
                    DispatchQueue.main.async {
                        self.recommendedCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func fetchNearbyPlace(for location: CLLocation, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let placesUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        let placesParameters: [String: Any] = [
            "location": "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            "radius": 500, // 검색 반경 (미터 단위)
            "key": Bundle.main.GOOGLE_MAP_API_KEY
        ]
        
        AF.request(placesUrl, parameters: placesParameters).responseJSON { response in
            if let data = response.data {
                let json = try? JSON(data: data)
                if let results = json?["results"].array, !results.isEmpty {
                    let firstResult = results[0]
                    if let lat = firstResult["geometry"]["location"]["lat"].double,
                       let lng = firstResult["geometry"]["location"]["lng"].double {
                        completion(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchStreetViewImage(for location: CLLocation, completion: @escaping (UIImage?) -> Void) {
        let metadataUrl = "https://maps.googleapis.com/maps/api/streetview/metadata"
        let metadataParameters: [String: Any] = [
            "location": "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            "key": Bundle.main.GOOGLE_MAP_API_KEY
        ]
        
        AF.request(metadataUrl, parameters: metadataParameters).responseJSON { response in
            if let data = response.data {
                let json = try? JSON(data: data)
                let status = json?["status"].string
                if status == "OK" {
                    // Street View 이미지 가져오기
                    let imageUrl = "https://maps.googleapis.com/maps/api/streetview"
                    let imageParameters: [String: Any] = [
                        "location": "\(location.coordinate.latitude),\(location.coordinate.longitude)",
                        "size": "600x400",
                        "key": Bundle.main.GOOGLE_MAP_API_KEY
                    ]
                    
                    AF.request(imageUrl, parameters: imageParameters).responseData { response in
                        if let data = response.data, let image = UIImage(data: data) {
                            completion(image)
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    // 가장 가까운 Street View 위치를 찾음
                    if let panoId = json?["pano_id"].string {
                        let nearestImageUrl = "https://maps.googleapis.com/maps/api/streetview"
                        let nearestImageParameters: [String: Any] = [
                            "pano": panoId,
                            "size": "600x400",
                            "key": Bundle.main.GOOGLE_MAP_API_KEY
                        ]
                        
                        AF.request(nearestImageUrl, parameters: nearestImageParameters).responseData { response in
                            if let data = response.data, let image = UIImage(data: data) {
                                completion(image)
                            } else {
                                completion(nil)
                            }
                        }
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
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
        if searchText.isEmpty {
            filteredAddresses = visitedAddresses
            tableView.isHidden = true // 검색어가 없으면 테이블 뷰 숨김
        } else {
            filteredAddresses = visitedAddresses.filter { $0.0.contains(searchText) } // address로 검색
            tableView.isHidden = false // 검색 결과가 있으면 테이블 뷰 표시
        }
        tableView.reloadData()
    }

    
    // UITableViewDataSource 메서드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAddresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        
        // 인덱스 범위 확인
        guard indexPath.row < filteredAddresses.count else {
            return cell // 빈 셀 반환 또는 기본 셀 반환
        }
        
        let (address, buildingName, _) = filteredAddresses[indexPath.row]
        if buildingName.isEmpty {
            cell.textLabel?.text = address
        } else {
            cell.textLabel?.text = "\(buildingName) - \(address)"
        }
        return cell
    }

}

class VisitedPlaceCell: UICollectionViewCell {
    var addressLabel: UILabel!
    var containerView: UIView!
    var imageView: UIImageView!
    
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
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.numberOfLines = 0 // 여러 줄 표시 가능하도록 설정
        addressLabel.textAlignment = .center
        addressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        containerView.addSubview(addressLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 5),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5),
            imageView.heightAnchor.constraint(equalToConstant: 120), // 이미지뷰 고정 높이
            
            addressLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10), // 간격 조정
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with address: String, image: UIImage?) {
        addressLabel.text = address
        imageView.image = image
    }
}
