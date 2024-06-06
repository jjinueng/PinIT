//
//  PlaceCollectionViewCell.swift
//  PinIT
//
//  Created by 김지윤 on 6/5/24.
//

import UIKit
import NMapsMap

class PlaceCollectionViewCell: UICollectionViewCell {
    var mapView: NMFMapView!
    var addressLabel: UILabel!
    var containerView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        // 컨테이너 뷰 설정
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.systemGray6
        containerView.layer.cornerRadius = 15
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        containerView.layer.shadowRadius = 4
        contentView.addSubview(containerView)

        // 네이버 지도 뷰 설정
        mapView = NMFMapView(frame: .zero)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mapView)

        // 주소 레이블 설정
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.numberOfLines = 0
        addressLabel.textAlignment = .center
        addressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        containerView.addSubview(addressLabel)

        // 패딩 설정 (각 방향마다 다른 크기)
        let topPadding: CGFloat = 5
        let leftPadding: CGFloat = 5
        let bottomPadding: CGFloat = 10
        let rightPadding: CGFloat = 5

        // 레이아웃 제약 조건 설정
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leftPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -rightPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -bottomPadding),

            mapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.7),

            addressLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 5),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with location: CLLocation, address: String) {
        addressLabel.text = address
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude))
        mapView.moveCamera(cameraUpdate)
    }
}
