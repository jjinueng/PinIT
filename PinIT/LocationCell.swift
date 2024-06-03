//
//  LocationCell.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit
import NMapsMap

class LocationCell: UICollectionViewCell {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var mapViewContainer: UIView!
    @IBOutlet weak var addressLabel: UILabel!
    var mapView: NMFMapView?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mapView?.removeFromSuperview()
        mapView = nil
    }

    func setupUI() {
        // 주소 라벨 설정
        addressLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        addressLabel.textColor = UIColor.darkGray
        addressLabel.numberOfLines = 0
        addressLabel.textAlignment = .center

        // mapViewContainer 설정
        mapViewContainer.layer.cornerRadius = 10
        mapViewContainer.layer.borderWidth = 1
        mapViewContainer.layer.borderColor = UIColor.lightGray.cgColor
        mapViewContainer.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
                    stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

                    mapViewContainer.heightAnchor.constraint(equalToConstant: 150),
                    addressLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                    addressLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
                ])
    }

    func configure(address: String, coordinate: NMGLatLng) {
        addressLabel.text = address

        // NMFMapView 설정
        mapView = NMFMapView(frame: mapViewContainer.bounds)
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapViewContainer.addSubview(mapView!)

        // 지도 위치 설정
        let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
        mapView?.moveCamera(cameraUpdate)

        // 마커 추가
        let marker = NMFMarker(position: coordinate)
        marker.iconTintColor = UIColor.blue  // 원하는 색상으로 변경
        marker.width = 24  // 원하는 너비로 변경
        marker.height = 34
        marker.mapView = mapView

        // 제스처 비활성화
        mapView?.isScrollGestureEnabled = false
        mapView?.isZoomGestureEnabled = false
        mapView?.isTiltGestureEnabled = false
        mapView?.isRotateGestureEnabled = false
    }
}
