//
//  ListViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit
import CoreLocation

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var collectionView: UICollectionView!
    var savedPlaces: [(location: CLLocation, address: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadSavedPlaces()

        NotificationCenter.default.addObserver(self, selector: #selector(loadSavedPlaces), name: .didSaveLocation, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func loadSavedPlaces() {
        if let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Double]] {
            savedPlaces.removeAll()
            for location in savedLocations {
                let latitude = location["latitude"] ?? 0.0
                let longitude = location["longitude"] ?? 0.0
                let location = CLLocation(latitude: latitude, longitude: longitude)
                savedPlaces.append((location: location, address: ""))
            }
            collectionView.reloadData()
            fetchAddressesForSavedPlaces()
        }
    }

    func fetchAddressesForSavedPlaces() {
        for (index, place) in savedPlaces.enumerated() {
            reverseGeocodeLocation(location: place.location) { address in
                self.savedPlaces[index].address = address
                DispatchQueue.main.async {
                    self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                }
            }
        }
    }

    func reverseGeocodeLocation(location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks, let placemark = placemarks.first {
                if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    var fullAddress = addrList.joined(separator: ", ")
                    if fullAddress.hasPrefix("대한민국") {
                        fullAddress = String(fullAddress.dropFirst("대한민국".count)).trimmingCharacters(in: .whitespaces)
                    }
                    completion(fullAddress)
                } else {
                    completion("주소를 찾을 수 없습니다")
                }
            } else {
                completion("주소를 찾을 수 없습니다")
            }
        }
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PlaceCollectionViewCell.self, forCellWithReuseIdentifier: "PlaceCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return savedPlaces.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceCell", for: indexPath) as! PlaceCollectionViewCell
            let place = savedPlaces[indexPath.row]
            cell.configure(with: place.location, address: place.address)
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let padding: CGFloat = 10
            let collectionViewSize = collectionView.frame.size.width - padding

            return CGSize(width: collectionViewSize / 2, height: 200)
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let place = savedPlaces[indexPath.row]
            let detailVC = PlaceDetailViewController()
            detailVC.place = place
            detailVC.onSave = { [weak self] nickname, description, category, location in
                self?.savePlaceDetail(nickname: nickname, description: description, category: category, location: location)
            }
            present(detailVC, animated: true, completion: nil)
        }

        func savePlaceDetail(nickname: String, description: String, category: String, location: CLLocation) {
            var savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []

            // 기존 장소를 찾아 업데이트하거나 새로운 장소를 추가
            if let index = savedLocations.firstIndex(where: {
                guard let lat = $0["latitude"] as? Double, let lng = $0["longitude"] as? Double else { return false }
                return lat == location.coordinate.latitude && lng == location.coordinate.longitude
            }) {
                savedLocations[index]["nickname"] = nickname
                savedLocations[index]["description"] = description
                savedLocations[index]["category"] = category
            } else {
                let newPlace: [String: Any] = [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "address": "",
                    "nickname": nickname,
                    "description": description,
                    "category": category
                ]
                savedLocations.append(newPlace)
            }

            UserDefaults.standard.set(savedLocations, forKey: "savedMarkerLocations")
            UserDefaults.standard.synchronize()

            // 데이터 다시 로드
            loadSavedPlaces()
        }
}
