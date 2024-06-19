//
//  MapViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/3/24.
//

import UIKit
import NMapsMap
import NMapsGeometry
import CoreLocation
import Alamofire
import SwiftyJSON
import Foundation

extension Notification.Name {
    static let didSaveLocation = Notification.Name("didSaveLocation")
}

class LocationManager {
    static let shared = LocationManager()
    
    private init() {}
    
    func saveLocations(locations: [[String: Any]]) {
        var savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        savedLocations.append(contentsOf: locations)
        UserDefaults.standard.set(savedLocations, forKey: "savedMarkerLocations")
        UserDefaults.standard.synchronize()
    }
    
    func loadLocations() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
    }
}

class MapViewController: UIViewController, CLLocationManagerDelegate, NMFMapViewTouchDelegate, UISearchBarDelegate {
    
    let locationManager = CLLocationManager()
    var markers: [NMFMarker] = []
    var loadedMarkers: [NMFMarker] = []
    var infoWindow: NMFInfoWindow?
    var selectedCategoryIndex = 0
    var isFirstLocationUpdate = true
    
    @IBOutlet weak var naverMapView: NMFNaverMapView!
    @IBOutlet weak var zoomControlView: NMFZoomControlView!
    @IBOutlet weak var saveLocationButton: UIButton!
    
    let categories = ["카테고리 전체", "음식점", "카페", "관광지", "숙소", "핫플", "카테고리 없음"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMapViewSettings()
        loadMarkerLocations()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadMarkerLocations), name: .didSaveLocation, object: nil)
        setupCategoryFilterButton()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didSaveLocation, object: nil)
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func setupMapViewSettings() {
        naverMapView.mapView.positionMode = .direction
        naverMapView.showCompass = true
        naverMapView.showLocationButton = false
        naverMapView.showZoomControls = false
        zoomControlView.mapView = naverMapView.mapView
        naverMapView.mapView.isTiltGestureEnabled = true
        naverMapView.mapView.isRotateGestureEnabled = true
        naverMapView.mapView.touchDelegate = self

        let currentLocationButton = UIButton(type: .custom)
        currentLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        currentLocationButton.backgroundColor = .white
        currentLocationButton.layer.cornerRadius = 25
        currentLocationButton.layer.shadowColor = UIColor.black.cgColor
        currentLocationButton.layer.shadowOpacity = 0.3
        currentLocationButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        currentLocationButton.layer.shadowRadius = 4
        currentLocationButton.tintColor = UIColor(hex: "#CE3B3D")
        currentLocationButton.addTarget(self, action: #selector(moveToCurrentLocation), for: .touchUpInside)
        
        view.addSubview(currentLocationButton)

        let saveLocationButton = UIButton(type: .custom)
        saveLocationButton.setImage(UIImage(systemName: "plus"), for: .normal)
        saveLocationButton.backgroundColor = .white
        saveLocationButton.layer.cornerRadius = 25
        saveLocationButton.layer.shadowColor = UIColor.black.cgColor
        saveLocationButton.layer.shadowOpacity = 0.3
        saveLocationButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        saveLocationButton.layer.shadowRadius = 4
        saveLocationButton.tintColor = UIColor(hex: "#CE3B3D")
        saveLocationButton.addTarget(self, action: #selector(showSaveLocationOptions), for: .touchUpInside)
        
        view.addSubview(saveLocationButton)

        currentLocationButton.translatesAutoresizingMaskIntoConstraints = false
        saveLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            currentLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentLocationButton.widthAnchor.constraint(equalToConstant: 50),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveLocationButton.widthAnchor.constraint(equalToConstant: 50),
            saveLocationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func setupCategoryFilterButton() {
        let categoryFilterButton = UIButton(type: .custom)
        categoryFilterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        categoryFilterButton.backgroundColor = .white
        categoryFilterButton.layer.cornerRadius = 25
        categoryFilterButton.layer.shadowColor = UIColor.black.cgColor
        categoryFilterButton.layer.shadowOpacity = 0.3
        categoryFilterButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        categoryFilterButton.layer.shadowRadius = 4
        categoryFilterButton.tintColor = UIColor(hex: "#CE3B3D")
        categoryFilterButton.addTarget(self, action: #selector(toggleCategory), for: .touchUpInside)
        
        view.addSubview(categoryFilterButton)

        categoryFilterButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryFilterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            categoryFilterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            categoryFilterButton.widthAnchor.constraint(equalToConstant: 50),
            categoryFilterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func toggleCategory() {
        selectedCategoryIndex = (selectedCategoryIndex + 1) % categories.count
        filterMarkersByCategory()
        showSnackbar(message: "카테고리 : \(categories[selectedCategoryIndex])")
    }
    
    func filterMarkersByCategory() {
        let selectedCategory = categories[selectedCategoryIndex]
        for marker in loadedMarkers {
            if selectedCategory == "카테고리 전체" {
                marker.mapView = naverMapView.mapView
            } else if selectedCategory == "카테고리 없음" {
                let category = marker.userInfo["category"] as? String
                marker.mapView = (category == "") ? naverMapView.mapView : nil
            } else {
                let category = marker.userInfo["category"] as? String
                marker.mapView = (category == selectedCategory) ? naverMapView.mapView : nil
            }
        }
    }
    
    var currentSnackbar: UILabel?

    func showSnackbar(message: String) {
        if let currentSnackbar = currentSnackbar {
            UIView.animate(withDuration: 0.3, animations: {
                currentSnackbar.alpha = 0
            }) { _ in
                currentSnackbar.removeFromSuperview()
            }
        }

        let snackbar = UILabel()
        snackbar.text = message
        snackbar.textAlignment = .center
        snackbar.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        snackbar.textColor = UIColor.darkGray
        snackbar.layer.cornerRadius = 15
        snackbar.clipsToBounds = true
        snackbar.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        view.addSubview(snackbar)
        
        snackbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            snackbar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            snackbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70),
            snackbar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            snackbar.heightAnchor.constraint(equalToConstant: 40)
        ])

        snackbar.alpha = 0
        UIView.animate(withDuration: 0.5, animations: {
            snackbar.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
                snackbar.alpha = 0
            }) { _ in
                snackbar.removeFromSuperview()
                if self.currentSnackbar == snackbar {
                    self.currentSnackbar = nil
                }
            }
        }

        currentSnackbar = snackbar
    }

    @objc func moveToCurrentLocation() {
        guard let currentLocation = locationManager.location else { return }
        let coord = NMGLatLng(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))
        isFirstLocationUpdate = false
    }
    
    @IBAction func saveMarkerLocations(_ sender: UIButton) {
        showSaveLocationOptions()
    }
    
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        infoWindow?.close()
        let marker = NMFMarker(position: latlng)
        removeMarkers()
        marker.iconTintColor = UIColor.red
        marker.width = 20
        marker.height = 26
        marker.mapView = mapView
        marker.zIndex = 4
        reverseGeocodeCoordinate(marker.position) { [weak self] buildingName, address in
            guard let self = self else { return }
            if let buildingName = buildingName {
                marker.captionText = buildingName
                marker.subCaptionText = address!
            } else {
                marker.captionText = address!
            }
            self.markers.append(marker)
        }
    }
    
    func removeMarkers() {
        markers.forEach { $0.mapView = nil }
        markers.removeAll()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if isFirstLocationUpdate, let location = locations.last {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            naverMapView.mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))
            isFirstLocationUpdate = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    @objc func loadMarkerLocations() {
        guard let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] else { return }
        loadedMarkers.forEach { $0.mapView = nil }
        loadedMarkers.removeAll()
        for location in savedLocations {
            let lat = location["latitude"] as? Double ?? 0.0
            let lng = location["longitude"] as? Double ?? 0.0
            let buildingName = location["buildingName"] as? String ?? ""
            let fullAddress = location["fullAddress"] as? String ?? ""
            let marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))

            marker.iconImage = NMF_MARKER_IMAGE_BLACK
            marker.iconTintColor = UIColor(hex: location["categoryColor"] as? String ?? "#00FF00")
            marker.width = 24
            marker.height = 34
            
            marker.captionText = buildingName.isEmpty ? fullAddress : buildingName
            marker.subCaptionText = buildingName.isEmpty ? "" : fullAddress
            
            marker.captionTextSize = 0
            marker.subCaptionTextSize = 0
            
            marker.userInfo = ["category": location["category"] as? String ?? ""]
            
            marker.touchHandler = { [weak self] overlay -> Bool in
                self?.handleMarkerTap(marker: overlay as! NMFMarker)
                return true
            }
            marker.mapView = naverMapView.mapView
            loadedMarkers.append(marker)
        }
        filterMarkersByCategory()
    }
    
    func handleMarkerTap(marker: NMFMarker) {
        let coordinate = CLLocationCoordinate2D(latitude: marker.position.lat, longitude: marker.position.lng)
        let title = marker.captionText
        reverseGeocodeCoordinate(NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)) { buildingName, address in
            self.showInfoWindow(at: marker.position, with: title)
        }
    }
    
    func deleteMarker(marker: NMFMarker) {
        marker.mapView = nil
        loadedMarkers.removeAll { $0 == marker }
        updateStoredLocations()
    }
    
    func updateStoredLocations() {
        let updatedLocations = loadedMarkers.map { marker -> [String: Any] in
            return [
                "latitude": marker.position.lat,
                "longitude": marker.position.lng,
                "buildingName": marker.captionText,
                "fullAddress": marker.subCaptionText,
                "categoryColor": marker.iconTintColor.hexString ?? "#00FF00",
                "category": marker.userInfo["category"] as? String ?? ""
            ]
        }
        UserDefaults.standard.set(updatedLocations, forKey: "savedMarkerLocations")
        UserDefaults.standard.synchronize()
    }
    
    func reverseGeocodeCoordinate(_ position: NMGLatLng, completion: @escaping (String?, String?) -> Void) {
        let location = CLLocation(latitude: position.lat, longitude: position.lng)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks, let placemark = placemarks.first {
                var buildingName: String? = placemark.name
                
                if let thoroughfare = placemark.thoroughfare, let name = placemark.name, name.contains(thoroughfare) {
                    buildingName = nil
                }
                if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    var fullAddress = addrList.joined(separator: ", ")
                    
                    if fullAddress.hasPrefix("대한민국") {
                        fullAddress = String(fullAddress.dropFirst("대한민국".count)).trimmingCharacters(in: .whitespaces)
                    } else if let commaIndex = fullAddress.firstIndex(of: ",") {
                        fullAddress = String(fullAddress[commaIndex...]).trimmingCharacters(in: .whitespaces)
                        fullAddress = String(fullAddress.dropFirst(", 대한민국".count)).trimmingCharacters(in: .whitespaces)
                    }
                    if let commaIndex = fullAddress.firstIndex(of: ",") {
                        fullAddress = String(fullAddress[..<commaIndex])
                    }
                    completion(buildingName, fullAddress)
                }
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func showInfoWindow(at position: NMGLatLng, with address: String) {
        infoWindow?.close()
    
        let infoWindow = NMFInfoWindow()
        let dataSource = CustomInfoWindowDataSource(title: address)
        infoWindow.dataSource = dataSource
        dataSource.title = address
        infoWindow.dataSource = dataSource
        infoWindow.position = position
        infoWindow.open(with: naverMapView.mapView)
        
        self.infoWindow = infoWindow
    }
    
    @objc func showSaveLocationOptions() {
        let alertController = UIAlertController(title: "위치 저장", message: "저장할 위치를 선택하세요.", preferredStyle: .actionSheet)
        
        let saveCurrentLocationAction = UIAlertAction(title: "현재 위치 저장", style: .default) { [weak self] _ in
            self?.saveCurrentLocation()
        }
        
        let saveSelectedLocationAction = UIAlertAction(title: "선택한 위치 저장", style: .default) { [weak self] _ in
            self?.saveSelectedLocation()
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alertController.addAction(saveCurrentLocationAction)
        alertController.addAction(saveSelectedLocationAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func saveCurrentLocation() {
        guard let currentLocation = locationManager.location else { return }
        
        let marker = NMFMarker(position: NMGLatLng(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude))
        reverseGeocodeCoordinate(NMGLatLng(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude)) { [weak self] buildingName, address in
            guard let self = self else { return }
            let locationDict: [String: Any] = [
                "latitude": currentLocation.coordinate.latitude,
                "longitude": currentLocation.coordinate.longitude,
                "buildingName": buildingName ?? "",
                "fullAddress": address ?? "",
                "isFavorite": false,
                "categoryColor": "#00FF00",
                "category": ""
            ]
            LocationManager.shared.saveLocations(locations: [locationDict])
            NotificationCenter.default.post(name: .didSaveLocation, object: nil)
        }
    }
    
    func saveSelectedLocation() {
        guard let selectedMarker = markers.first else {
            let alert = UIAlertController(title: "알림", message: "저장할 위치를 선택해주세요.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        
        let buildingName: String
        let fullAddress: String

        if selectedMarker.subCaptionText.isEmpty {
            buildingName = ""
            fullAddress = selectedMarker.captionText
        } else {
            buildingName = selectedMarker.captionText
            fullAddress = selectedMarker.subCaptionText
        }

        let locationDict: [String: Any] = [
            "latitude": selectedMarker.position.lat,
            "longitude": selectedMarker.position.lng,
            "buildingName": buildingName,
            "fullAddress": fullAddress,
            "isFavorite": false,
            "categoryColor": "#00FF00",
            "category": ""
        ]
        
        LocationManager.shared.saveLocations(locations: [locationDict])
        NotificationCenter.default.post(name: .didSaveLocation, object: nil)
    }

}

class CustomInfoWindowDataSource: NSObject, NMFOverlayImageDataSource {
    var title: String
    
    init(title: String) {

        self.title = title
    }
    
    func view(with overlay: NMFOverlay) -> UIView {
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.sizeToFit()

        let padding: CGFloat = 8
        let paddedLabel = UIView(frame: CGRect(x: 0, y: 0, width: label.frame.width + padding * 2, height: label.frame.height + padding * 2))
        paddedLabel.backgroundColor = UIColor.white
        paddedLabel.layer.cornerRadius = 8
        paddedLabel.clipsToBounds = true
        paddedLabel.addSubview(label)
        label.center = paddedLabel.center
        
        return paddedLabel
    }
}
