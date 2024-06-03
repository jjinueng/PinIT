//
//  LocationCollectionViewCell.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit

class LocationCollectionViewCell: UICollectionViewCell {
    
    let latitudeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()
    
    let longitudeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(latitudeLabel)
        contentView.addSubview(longitudeLabel)
        
        NSLayoutConstraint.activate([
            latitudeLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            latitudeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            latitudeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            longitudeLabel.topAnchor.constraint(equalTo: latitudeLabel.bottomAnchor),
            longitudeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            longitudeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            longitudeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(latitude: Double, longitude: Double) {
        latitudeLabel.text = "Latitude: \(latitude)"
        longitudeLabel.text = "Longitude: \(longitude)"
    }
}

