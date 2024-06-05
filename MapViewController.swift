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
    @IBOutlet weak var searchBar: UISearchBar!
    
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
        // UserDefaults에서 기존 위치 데이터 불러오기
        var savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Double]] ?? []
        
        // 현재 마커 배열에서 위치 데이터 추출
        let newLocations = markers.map { ["latitude": $0.position.lat, "longitude": $0.position.lng] }
        
        // 기존 위치 데이터에 새 위치 데이터 추가
        savedLocations.append(contentsOf: newLocations)
        
        // 업데이트된 위치 데이터를 UserDefaults에 저장
        UserDefaults.standard.set(savedLocations, forKey: "savedMarkerLocations")
        UserDefaults.standard.synchronize()
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
        markers.append(marker)
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
        reverseGeocodeCoordinate(marker.position)
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
    
    
    func reverseGeocodeCoordinate(_ position: NMGLatLng) {
        let url = URL(string: "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=\(position.lng),\(position.lat)&output=json&orders=addr")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(Bundle.main.NAVER_MAP_API_KEY_ID, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue(Bundle.main.NAVER_MAP_API_KEY, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let region = results.first?["region"] as? [String: Any],
               let area1 = region["area1"] as? [String: Any],
               let area2 = region["area2"] as? [String: Any],
               let area3 = region["area3"] as? [String: Any],
               let land = results.first?["land"] as? [String: Any] {
                
                let area1Name = area1["name"] as? String ?? ""
                let area2Name = area2["name"] as? String ?? ""
                let area3Name = area3["name"] as? String ?? ""
                let number1 = land["number1"] as? String ?? ""
                let number2 = land["number2"] as? String ?? ""
                
                var fullAddress = "\(area1Name) \(area2Name) \(area3Name), \(number1)"
                if !number2.isEmpty {
                    fullAddress += "-\(number2)"
                }
                DispatchQueue.main.async {
                    self?.showInfoWindow(at: position, with: fullAddress)
                    print(fullAddress)
                }
            } else {
                print("주소 정보를 파싱할 수 없습니다.")
            }
        }
        task.resume()
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
