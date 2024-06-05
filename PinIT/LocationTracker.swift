//
//  LocationTracker.swift
//  PinIT
//
//  Created by 김지윤 on 6/5/24.
//

import UIKit
import CoreLocation

class LocationTracker: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    var visitCounts: [String: Int] = UserDefaults.standard.dictionary(forKey: "visitCounts") as? [String: Int] ?? [:]

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }

    func startMonitoringRegion(at coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        locationManager.startMonitoring(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let identifier = region.identifier
        visitCounts[identifier] = (visitCounts[identifier] ?? 0) + 1
        UserDefaults.standard.set(visitCounts, forKey: "visitCounts")
    }
}
