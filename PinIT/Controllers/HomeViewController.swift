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
    var location: Location?
    
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
    var searchResetTimer: Timer?
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchResetTimer?.invalidate()
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

        let reversedLocations = Array(savedLocations.reversed())

        visitedLocations = reversedLocations.map { dict in
            CLLocation(latitude: dict["latitude"] as! Double, longitude: dict["longitude"] as! Double)
        }
        visitedAddresses = Array(repeating: ("", "", nil), count: reversedLocations.count)
        
        for (index, location) in visitedLocations.enumerated() {
            let buildingName = reversedLocations[index]["buildingName"] as? String ?? ""
            let fullAddress = reversedLocations[index]["fullAddress"] as? String ?? ""
            let address = fullAddress

            fetchStreetViewImage(for: location) { [weak self] image in
                guard let self = self else { return }
                self.visitedAddresses[index] = (address, buildingName, image)
                DispatchQueue.main.async {
                    self.filteredAddresses = self.visitedAddresses
                    self.visitedCollectionView.reloadData()
                    self.tableView.reloadData()
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

        if let searchTextField = searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = UIColor.systemGray6
            searchTextField.layer.cornerRadius = 15
            searchTextField.layer.masksToBounds = true
            searchTextField.borderStyle = .none
        }
  
        searchBar.layer.cornerRadius = 15
        searchBar.layer.masksToBounds = true
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 10, vertical: 0)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 15
        tableView.layer.masksToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddressCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint.isActive = true
        tableView.isHidden = true
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
       
        tableView.layer.shadowColor = UIColor.black.cgColor
        tableView.layer.shadowOpacity = 0.2
        tableView.layer.shadowOffset = CGSize(width: 0, height: 2)
        tableView.layer.shadowRadius = 4
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

        NSLayoutConstraint.activate([
            recentPlacesLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            recentPlacesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
    }
    
    func setupVisitedCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 200, height: 200)
        
        visitedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        visitedCollectionView.delegate = self
        visitedCollectionView.dataSource = self
        visitedCollectionView.register(VisitedPlaceCell.self, forCellWithReuseIdentifier: "VisitedPlaceCell")
        visitedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        visitedCollectionView.backgroundColor = .white
        contentView.addSubview(visitedCollectionView)
        

        NSLayoutConstraint.activate([
            visitedCollectionView.topAnchor.constraint(equalTo: recentPlacesLabel.bottomAnchor, constant: 10),
            visitedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            visitedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            visitedCollectionView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func setupRecommendedPlacesLabel() {
        recommendedPlacesLabel = UILabel()
        recommendedPlacesLabel.text = "이 장소는 어때요?"
        recommendedPlacesLabel.font = UIFont.boldSystemFont(ofSize: 18)
        recommendedPlacesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendedPlacesLabel)

        NSLayoutConstraint.activate([
            recommendedPlacesLabel.topAnchor.constraint(equalTo: visitedCollectionView.bottomAnchor, constant: 10),
            recommendedPlacesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
    }
    
    func setupRecommendedCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 200, height: 200)
        
        recommendedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        recommendedCollectionView.delegate = self
        recommendedCollectionView.dataSource = self
        recommendedCollectionView.register(VisitedPlaceCell.self, forCellWithReuseIdentifier: "VisitedPlaceCell")
        recommendedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        recommendedCollectionView.backgroundColor = .white
        contentView.addSubview(recommendedCollectionView)

        NSLayoutConstraint.activate([
            recommendedCollectionView.topAnchor.constraint(equalTo: recommendedPlacesLabel.bottomAnchor, constant: 10),
            recommendedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recommendedCollectionView.heightAnchor.constraint(equalToConstant: 200),
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == visitedCollectionView {
            let location = visitedLocations[indexPath.row]
            let addressTuple = filteredAddresses[indexPath.row]
            showDetailPopup(for: location, address: addressTuple.0, buildingName: addressTuple.1, image: addressTuple.2)
        }
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
            reverseGeocodeLocation(location: currentLocation) { [weak self] dongName in
                guard let self = self, let dongName = dongName else { return }
                self.searchPlaces(query: dongName)
            }
        }
    }
    
    func reverseGeocodeLocation(location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks, let placemark = placemarks.first {
                let dongName = placemark.subLocality
                completion(dongName)
            } else {
                completion(nil)
            }
        }
    }
    
    func searchPlaces(query: String) {
        let clientId = Bundle.main.NAVER_SEARCH_API_KEY_ID
        let clientSecret = Bundle.main.NAVER_SEARCH_API_KEY

        let fullQuery = "\(query) 가볼만한곳"
        
        let urlString = "https://openapi.naver.com/v1/search/local.json"
        guard let url = URL(string: "\(urlString)?query=\(fullQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&display=5") else {
            print("Invalid URL")
            return
        }
        
        let headers: HTTPHeaders = [
            "X-Naver-Client-Id": clientId,
            "X-Naver-Client-Secret": clientSecret
        ]
        
        AF.request(url, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print(json)
                self.handleSearchResults(json)
            case .failure(let error):
                print(error)
            }
        }
    }


    func handleSearchResults(_ json: JSON) {
        var places: [TrendingPlace] = []
        for item in json["items"].arrayValue {
            let title = item["title"].stringValue
            let mapx = item["mapx"].doubleValue
            let mapy = item["mapy"].doubleValue
            let latitude = convertToLatitude(mapy: mapy)
            let longitude = convertToLongitude(mapx: mapx)
            let address = item["address"].stringValue
            places.append(TrendingPlace(title: title, adress: address, latitude: latitude, longitude: longitude))
        }
        generateRecommendedPlaces(from: places)
    }

    func convertToLatitude(mapy: Double) -> Double {
        return mapy / 10000000.0
    }

    func convertToLongitude(mapx: Double) -> Double {
        return mapx / 10000000.0
    }

    func generateRecommendedPlaces(from places: [TrendingPlace]) {
        recommendedPlaces = places.map { ($0.title, nil) }
        for (index, place) in places.enumerated() {
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            fetchStreetViewImage(for: placeLocation) { image in
                self.recommendedPlaces[index].1 = image
                DispatchQueue.main.async {
                    self.recommendedCollectionView.reloadData()
                }
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredAddresses = visitedAddresses
            tableView.isHidden = true
        } else {
            filteredAddresses = visitedAddresses.filter { $0.0.contains(searchText) }
            tableView.isHidden = false
        }
        tableView.reloadData()
        
        searchResetTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(resetSearchBar), userInfo: nil, repeats: false)
    }
    
    @objc func resetSearchBar() {
        searchBar.text = ""
        filteredAddresses = visitedAddresses
        tableView.isHidden = true
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAddresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)

        guard indexPath.row < filteredAddresses.count else {
            return cell
        }
        
        let (address, buildingName, _) = filteredAddresses[indexPath.row]
        if buildingName.isEmpty {
            cell.textLabel?.text = address
        } else {
            cell.textLabel?.text = "\(buildingName) - \(address)"
        }

        cell.backgroundColor = .white
        cell.textLabel?.textAlignment = .center
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let addressTuple = filteredAddresses[indexPath.row]
        let location = visitedLocations[indexPath.row]
        showDetailPopup(for: location, address: addressTuple.0, buildingName: addressTuple.1, image: addressTuple.2)
    }

    func showDetailPopup(for location: CLLocation, address: String, buildingName: String, image: UIImage?) {
        let detailVC = DetailPopupViewController()
        detailVC.location = Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            buildingName: buildingName,
            fullAddress: address,
            createdAt: Date(),
            isFavorite: false,
            nickname: "",
            memo: "",
            category: "",
            categoryColor: .white,
            images: image != nil ? [image!] : []
        )
        present(detailVC, animated: true, completion: nil)
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
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowColor = UIColor.black.cgColor
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
        addressLabel.numberOfLines = 0
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
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            addressLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
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
