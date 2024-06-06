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


extension Bundle {
    
    var NAVER_MAP_API_KEY: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["NAVER_MAP_API_KEY"] as? String else {
            fatalError("NAVER_MAP_API_KEY error")
        }
        return key
    }
    
    var NAVER_MAP_API_KEY_ID: String {
        guard let file = self.path(forResource: "API", ofType: "plist") else { return "" }
        
        // .plist를 딕셔너리로 받아오기
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        
        // 딕셔너리에서 값 찾기
        guard let key = resource["NAVER_MAP_API_KEY_ID"] as? String else {
            fatalError("NAVER_MAP_API_KEY_ID error")
        }
        return key
    }
}

extension Notification.Name {
    static let didSaveLocation = Notification.Name("didSaveLocation")
}

class LocationManager { // 헬퍼 
    static let shared = LocationManager()
    
    private init() {}
    
    func saveLocations(locations: [[String: Double]]) {
        var savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Double]] ?? []
        savedLocations.append(contentsOf: locations)
        UserDefaults.standard.set(savedLocations, forKey: "savedMarkerLocations")
        UserDefaults.standard.synchronize()
    }
    
    func loadLocations() -> [[String: Double]] {
        return UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Double]] ?? []
    }
}


class MapViewController: UIViewController, CLLocationManagerDelegate, NMFMapViewTouchDelegate, UISearchBarDelegate {
    
    
    let locationManager = CLLocationManager()
    var markers: [NMFMarker] = []
    var loadedMarkers: [NMFMarker] = []
    var infoWindow: NMFInfoWindow?
    
    @IBOutlet weak var naverMapView: NMFNaverMapView!
    @IBOutlet weak var zoomControlView: NMFZoomControlView!
    @IBOutlet weak var saveLocationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMapViewSettings()
        loadMarkerLocations()
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
        naverMapView.showLocationButton = true
        naverMapView.showZoomControls = false
        zoomControlView.mapView = naverMapView.mapView
        naverMapView.mapView.isTiltGestureEnabled = true
        naverMapView.mapView.isRotateGestureEnabled = true
        naverMapView.mapView.touchDelegate = self
    }
    
    
    @IBAction func saveMarkerLocations(_ sender: UIButton) {
        var savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        
        let newLocations = markers.map { marker -> [String: Any] in
            if(marker.subCaptionText == ""){
                return [
                    "latitude": marker.position.lat,
                    "longitude": marker.position.lng,
                    "buildingName": "",
                    "fullAddress": marker.captionText
                ]
            } else {
                return [
                    "latitude": marker.position.lat,
                    "longitude": marker.position.lng,
                    "buildingName": marker.captionText,
                    "fullAddress": marker.subCaptionText
                ]
            }
        }
        
        
        savedLocations.append(contentsOf: newLocations)
        
        UserDefaults.standard.set(savedLocations, forKey: "savedMarkerLocations")
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: .didSaveLocation, object: nil)
        
        print("Updated and saved marker locations: \(savedLocations)")
        
        loadMarkerLocations()
    }
    
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        infoWindow?.close()
        let marker = NMFMarker(position: latlng)
        removeMarkers()
        marker.iconTintColor = UIColor.red
        marker.width = 20
        marker.height = 26
        marker.mapView = mapView
        reverseGeocodeCoordinate(marker.position) { [weak self] buildingName, address in
            guard let self = self else { return }
            if buildingName != nil {
                marker.captionText = buildingName!
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
        if let location = locations.last {
            naverMapView.mapView.moveCamera(NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func loadMarkerLocations() {
        guard let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Double]] else { return }
        for location in savedLocations {
            let lat = location["latitude"] ?? 0.0
            let lng = location["longitude"] ?? 0.0
            let marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))
            
            // 마커 색상 및 크기 설정
            marker.iconTintColor = UIColor.blue  // 원하는 색상으로 변경
            marker.width = 24  // 원하는 너비로 변경
            marker.height = 34  // 원하는 높이로 변경
            
            marker.touchHandler = { [weak self] overlay -> Bool in
                self?.handleMarkerTap(marker: overlay as! NMFMarker)
                return true
            }
            marker.mapView = naverMapView.mapView
            loadedMarkers.append(marker)
        }
    }
    
    func handleMarkerTap(marker: NMFMarker) {
        let coordinate = CLLocationCoordinate2D(latitude: marker.position.lat, longitude: marker.position.lng)
        reverseGeocodeCoordinate(NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)) { buildingName, address in
            // 마커 클릭 시 추가 기능을 구현할 수 있습니다.
        }
    }
    
    
    func deleteMarker(marker: NMFMarker) {
        marker.mapView = nil
        loadedMarkers.removeAll { $0 == marker }
        updateStoredLocations()
    }
    
    func updateStoredLocations() {
        let updatedLocations = loadedMarkers.map { ["latitude": $0.position.lat, "longitude": $0.position.lng] }
        UserDefaults.standard.set(updatedLocations, forKey: "savedMarkerLocations")
        UserDefaults.standard.synchronize()
    }
    
    
    func reverseGeocodeCoordinate(_ position: NMGLatLng, completion: @escaping (String?, String?) -> Void) {
        let location = CLLocation(latitude: position.lat, longitude: position.lng)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks, let placemark = placemarks.first {
                var buildingName: String? = placemark.name
                
                // placemark.name에 subThoroughfare가 포함되어 있는지 확인
                if let subThoroughfare = placemark.subThoroughfare, let name = placemark.name, name.contains(subThoroughfare) {
                    buildingName = nil
                }
                var fullAddress = placemark.thoroughfare ?? "No Address"
                if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    var fullAddress = addrList.joined(separator: ", ")
                    
                    // "대한민국" 문자열을 제거합니다.
                    if fullAddress.hasPrefix("대한민국") {
                        fullAddress = String(fullAddress.dropFirst("대한민국".count)).trimmingCharacters(in: .whitespaces)
                    } else if let commaIndex = fullAddress.firstIndex(of: ",") {
                        // "대한민국"으로 시작하지 않으면 첫 번째 콤마가 나올 때까지 삭제합니다.
                        fullAddress = String(fullAddress[commaIndex...]).trimmingCharacters(in: .whitespaces)
                        fullAddress = String(fullAddress.dropFirst(", 대한민국".count)).trimmingCharacters(in: .whitespaces)
                    }
                    // 쉼표를 찾고 첫 번째 쉼표 이후의 문자를 제거합니다.
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
        // 기존에 열려있는 InfoWindow 닫기
        infoWindow?.close()
        
        // InfoWindow 인스턴스 생성 및 구성
        let infoWindow = NMFInfoWindow()
        let dataSource = CustomInfoWindowDataSource(title: address)
        infoWindow.dataSource = dataSource
        dataSource.title = address
        infoWindow.dataSource = dataSource
        infoWindow.position = position
        infoWindow.open(with: naverMapView.mapView)
        
        // 새로운 InfoWindow 저장
        self.infoWindow = infoWindow
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
        label.font = UIFont.systemFont(ofSize: 12) // 글씨 크기 설정
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.sizeToFit()
        
        // 패딩 추가
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
