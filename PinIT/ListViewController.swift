//
//  ListViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit
import NMapsMap

class ListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var locations: [[String: Double]] = []
    var addresses: [(String, NMGLatLng)] = []
    let cellPadding: CGFloat = 8.0 // 패딩 값
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocationList), name: .didSaveLocation, object: nil)
        
        // UICollectionView 설정
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // UICollectionViewCell 등록
        let nib = UINib(nibName: "LocationCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "LocationCell")
        
        // 저장된 위치 데이터 불러오기
        locations = LocationManager.shared.loadLocations()
        
        // 위치 데이터를 주소로 변환
        convertLocationsToAddresses(locations: locations)
    }
    
    @objc func updateLocationList() {
        // 새로 저장된 위치 데이터 불러오기
        locations = LocationManager.shared.loadLocations()
        
        // 주소 목록 초기화 및 새로 변환
        addresses.removeAll()
        convertLocationsToAddresses(locations: locations)
    
    }
    

    func convertLocationsToAddresses(locations: [[String: Double]]) {
        for location in locations {
            let lat = location["latitude"] ?? 0.0
            let lng = location["longitude"] ?? 0.0
            let coordinate = NMGLatLng(lat: lat, lng: lng)
            
            // Reverse geocoding
            reverseGeocodeCoordinate(coordinate) { [weak self] address in
                guard let self = self else { return }
                self.addresses.append((address, coordinate))
                
                // 모든 주소를 변환한 후 컬렉션 뷰 갱신
                if self.addresses.count == locations.count {
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func reverseGeocodeCoordinate(_ position: NMGLatLng, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=\(position.lng),\(position.lat)&output=json&orders=addr")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(Bundle.main.NAVER_MAP_API_KEY_ID, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue(Bundle.main.NAVER_MAP_API_KEY, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                
                completion(fullAddress)
            } else {
                print("주소 정보를 파싱할 수 없습니다.")
            }
        }
        task.resume()
    }
    
    // UICollectionViewDataSource 메서드
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return addresses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LocationCell", for: indexPath) as! LocationCell
        let (address, coordinate) = addresses[indexPath.item]
        cell.configure(address: address, coordinate: coordinate)
        return cell
    }

    
}
