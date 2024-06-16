//
//  ListViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/4/24.
//

import UIKit

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var locations: [Location] = []
    var collectionView: UICollectionView!
    
    let dataSource = ["지역 전체", "서울", "인천", "강원", "충남", "충북", "경북", "경남", "전북", "전남", "세종", "대전", "대구", "울산", "부산", "제주"]
    let categorySource = ["카테고리 전체", "음식점", "카페", "관광지", "숙소", "핫플"]
    
    var selectedRegion: String = "지역 전체"
    var selectedCategory: String = "카테고리 전체"
    var isMultiSelecting: Bool = false
    var isFilteringFavorites: Bool = false
    var selectedItems: Set<IndexPath> = []
    
    let favoriteFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .lightGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let multiSelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("편집", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("삭제", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("즐겨찾기", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    let selectAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전체 선택", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("...", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var filterStackView: UIStackView!
    var editStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadVisitedPlaces()
        NotificationCenter.default.addObserver(self, selector: #selector(locationsDidUpdate), name: .didSaveLocation, object: nil)
    }
    
    @objc func locationsDidUpdate(notification: Notification) {
        loadVisitedPlaces()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() {
        favoriteFilterButton.addTarget(self, action: #selector(toggleFavoriteFilter), for: .touchUpInside)
        view.addSubview(favoriteFilterButton)
        
        let regionButton = createDropDownButton(title: "지역 전체", dataSource: dataSource) { [weak self] selected in
            self?.selectedRegion = selected
            self?.collectionView.reloadData()
        }
        regionButton.translatesAutoresizingMaskIntoConstraints = false
        
        let categoryButton = createDropDownButton(title: "카테고리 전체", dataSource: categorySource) { [weak self] selected in
            self?.selectedCategory = selected
            self?.collectionView.reloadData()
        }
        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        
        filterStackView = UIStackView(arrangedSubviews: [regionButton, categoryButton])
        filterStackView.axis = .horizontal
        filterStackView.spacing = 20
        filterStackView.alignment = .center
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterStackView)
        
        editStackView = UIStackView(arrangedSubviews: [selectAllButton, favoriteButton, deleteButton])
        editStackView.axis = .horizontal
        editStackView.spacing = 20
        editStackView.alignment = .center
        editStackView.translatesAutoresizingMaskIntoConstraints = false
        editStackView.isHidden = true
        view.addSubview(editStackView)
        
        multiSelectButton.addTarget(self, action: #selector(toggleMultiSelect), for: .touchUpInside)
        view.addSubview(multiSelectButton)
        
        deleteButton.addTarget(self, action: #selector(deleteSelectedItems), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteSelectedItems), for: .touchUpInside)
        selectAllButton.addTarget(self, action: #selector(selectAllItems), for: .touchUpInside)
        
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
        view.addSubview(menuButton)
        
        NSLayoutConstraint.activate([
            favoriteFilterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            favoriteFilterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            favoriteFilterButton.widthAnchor.constraint(equalToConstant: 40),
            favoriteFilterButton.heightAnchor.constraint(equalToConstant: 40),
            
            filterStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            
            editStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            
            multiSelectButton.centerYAnchor.constraint(equalTo: favoriteFilterButton.centerYAnchor),
            multiSelectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            menuButton.centerYAnchor.constraint(equalTo: favoriteFilterButton.centerYAnchor),
            menuButton.leadingAnchor.constraint(equalTo: multiSelectButton.trailingAnchor, constant: 20)
        ])
    }

    
    func createDropDownButton(title: String, dataSource: [String], action: @escaping (String) -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        
        let actionClosure: (UIAction) -> Void = { uiAction in
            button.setTitle(uiAction.title, for: .normal)
            action(uiAction.title)
        }
        
        var menuChildren: [UIMenuElement] = []
        for item in dataSource {
            menuChildren.append(UIAction(title: item, handler: actionClosure))
        }
        
        button.menu = UIMenu(options: .displayInline, children: menuChildren)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        
        return button
    }
    
    @objc func toggleFavoriteFilter() {
        isFilteringFavorites.toggle()
        favoriteFilterButton.setImage(UIImage(systemName: isFilteringFavorites ? "heart.fill" : "heart"), for: .normal)
        favoriteFilterButton.tintColor = isFilteringFavorites ? .red : .lightGray
        collectionView.reloadData()
    }
    
    @objc func toggleMultiSelect() {
        isMultiSelecting.toggle()
        selectedItems.removeAll()  // Clear selected items when toggling
        multiSelectButton.setTitle(isMultiSelecting ? "취소" : "편집", for: .normal)
        filterStackView.isHidden = isMultiSelecting
        editStackView.isHidden = !isMultiSelecting
        deleteButton.isHidden = !isMultiSelecting
        favoriteButton.isHidden = !isMultiSelecting
        selectAllButton.isHidden = !isMultiSelecting
        collectionView.reloadData()
    }
    
    @objc func deleteSelectedItems() {
        let sortedSelectedItems = selectedItems.sorted(by: >)
        for indexPath in sortedSelectedItems {
            locations.remove(at: indexPath.item)
        }
        selectedItems.removeAll()
        saveLocationDetails()
        collectionView.reloadData()
    }
    
    @objc func favoriteSelectedItems() {
        for indexPath in selectedItems {
            locations[indexPath.item].isFavorite = true
        }
        selectedItems.removeAll()
        saveFavoriteLocations()
        collectionView.reloadData()
    }
    
    @objc func selectAllItems() {
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            selectedItems.insert(IndexPath(item: item, section: 0))
        }
        collectionView.reloadData()
    }
    
    @objc func showMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteSelectedItems()
        }
        let favoriteAction = UIAlertAction(title: "즐겨찾기", style: .default) { [weak self] _ in
            self?.favoriteSelectedItems()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        menu.addAction(deleteAction)
        menu.addAction(favoriteAction)
        menu.addAction(cancelAction)
        
        present(menu, animated: true, completion: nil)
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.size.width / 2 - 15, height: 200)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.register(LocationCell.self, forCellWithReuseIdentifier: "LocationCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredLocations().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LocationCell", for: indexPath) as? LocationCell else {
            fatalError("Unable to dequeue LocationCell")
        }
        let location = filteredLocations()[indexPath.item]
        let isSelected = selectedItems.contains(indexPath)
        cell.configure(with: location, isMultiSelecting: isMultiSelecting, isSelected: isSelected)
        cell.favoriteButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.toggleFavorite(at: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isMultiSelecting {
            if selectedItems.contains(indexPath) {
                selectedItems.remove(indexPath)
            } else {
                selectedItems.insert(indexPath)
            }
            collectionView.reloadItems(at: [indexPath])
        } else {
            let location = filteredLocations()[indexPath.item]
            showDetailPopup(for: location, at: indexPath)
        }
    }
    
    func showDetailPopup(for location: Location, at indexPath: IndexPath) {
        let detailVC = DetailPopupViewController()
        detailVC.location = location
        detailVC.indexPath = indexPath
        detailVC.onSave = { [weak self] updatedLocation, indexPath in
            guard let self = self else { return }
            if let updatedLocation = updatedLocation {
                self.locations[indexPath.item] = updatedLocation
            } else {
                self.locations.remove(at: indexPath.item)
            }
            self.saveFavoriteLocations()  // 변경된 데이터 저장
            self.collectionView.reloadData()
        }
        present(detailVC, animated: true, completion: nil)
    }
    
    func saveLocationDetails() {
        let data = locations.map { location -> [String: Any] in
            var dict: [String: Any] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "isFavorite": location.isFavorite,
                "buildingName": location.buildingName ?? "",
                "fullAddress": location.fullAddress ?? "",
                "createdAt": location.createdAt.timeIntervalSince1970,
                "nickname": location.nickname ?? "",
                "memo": location.memo ?? "",
                "category": location.category ?? "",
                "categoryColor": location.categoryColor?.hexString ?? "#FFFFFF"
            ]
            let imageData = location.images.compactMap { $0.jpegData(compressionQuality: 1.0) }
            dict["images"] = imageData
            return dict
        }
        UserDefaults.standard.set(data, forKey: "savedMarkerLocations")
    }

    func saveFavoriteLocations() {
        let favorites = locations.filter { $0.isFavorite }
        let data = favorites.map { location -> [String: Any] in
            var dict: [String: Any] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "isFavorite": location.isFavorite,
                "buildingName": location.buildingName ?? "",
                "fullAddress": location.fullAddress ?? "",
                "createdAt": location.createdAt.timeIntervalSince1970,
                "nickname": location.nickname ?? "",
                "memo": location.memo ?? "",
                "category": location.category ?? "",
                "categoryColor": location.categoryColor?.hexString ?? "#FFFFFF"
            ]
            let imageData = location.images.compactMap { $0.jpegData(compressionQuality: 1.0) }
            dict["images"] = imageData
            return dict
        }
        UserDefaults.standard.set(data, forKey: "FavoriteLocations")
        UserDefaults.standard.synchronize()
    }

    func loadVisitedPlaces() {
        let savedLocations = UserDefaults.standard.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        let reversedLocations = Array(savedLocations.reversed())
        
        locations = reversedLocations.map { dict in
            let imageDataArray = dict["images"] as? [Data] ?? []
            let images = imageDataArray.compactMap { UIImage(data: $0) }
            
            return Location(
                latitude: dict["latitude"] as? Double ?? 0.0,
                longitude: dict["longitude"] as? Double ?? 0.0,
                buildingName: dict["buildingName"] as? String ?? "",
                fullAddress: dict["fullAddress"] as? String ?? "",
                createdAt: Date(timeIntervalSince1970: dict["createdAt"] as? TimeInterval ?? 0),
                isFavorite: dict["isFavorite"] as? Bool ?? false,
                nickname: dict["nickname"] as? String ?? "",
                memo: dict["memo"] as? String ?? "",
                category: dict["category"] as? String ?? "",
                categoryColor: UIColor(hex: dict["categoryColor"] as? String ?? "#FFFFFF"),
                images: images
            )
        }
        loadFavoriteLocations() // Ensure favorite states are loaded
        collectionView.reloadData()
    }


    func toggleFavorite(at indexPath: IndexPath) {
        locations[indexPath.row].isFavorite.toggle()
        collectionView.reloadItems(at: [indexPath])
        saveFavoriteLocations()
    }
    
    
    func loadFavoriteLocations() {
        guard let savedFavorites = UserDefaults.standard.array(forKey: "FavoriteLocations") as? [[String: Any]] else { return }
        for (index, location) in locations.enumerated() {
            if savedFavorites.contains(where: {
                guard let lat = $0["latitude"] as? Double, let lng = $0["longitude"] as? Double else { return false }
                return lat == location.latitude && lng == location.longitude
            }) {
                locations[index].isFavorite = true
            }
        }
        collectionView.reloadData()
    }
    
    func filteredLocations() -> [Location] {
        return locations.filter { location in
            let matchesFavorite = !isFilteringFavorites || location.isFavorite
            let matchesRegion = selectedRegion == "지역 전체" || location.region == selectedRegion
            let matchesCategory = selectedCategory == "카테고리 전체" || location.category == selectedCategory
            return matchesFavorite && matchesRegion && matchesCategory
        }
    }
}

class LocationCell: UICollectionViewCell {
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var imageView: UIImageView!
    var favoriteButton: UIButton!
    var selectionIndicator: UIImageView!
    var noImageLabel: UILabel!
    
    var favoriteButtonTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        applyStyling()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        imageView = UIImageView()
        selectionIndicator = UIImageView()
        noImageLabel = UILabel()
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        noImageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(selectionIndicator)
        contentView.addSubview(noImageLabel)
        
        favoriteButton = UIButton(type: .system)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(favoriteButton)
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.tintColor = .gray
        
        selectionIndicator.image = UIImage(systemName: "circle")
        selectionIndicator.tintColor = .gray
        
        noImageLabel.text = "이미지 없음"
        noImageLabel.textAlignment = .center
        noImageLabel.textColor = .lightGray
        noImageLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            
            noImageLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            noImageLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),
            
            selectionIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            selectionIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 20),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func applyStyling() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowColor = UIColor.black.cgColor
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.numberOfLines = 0
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
    }
    
    func configure(with location: Location, isMultiSelecting: Bool, isSelected: Bool) {
        if location.nickname == "" {
            titleLabel.text = location.buildingName
        } else {
            titleLabel.text = location.nickname
        }
        print(location.nickname)
        subtitleLabel.text = location.fullAddress

        // location의 images 배열에서 첫 번째 이미지를 가져오기
        if let firstImage = location.images.first {
            imageView.image = firstImage
            noImageLabel.isHidden = true
        } else {
            imageView.image = nil
            noImageLabel.isHidden = false
        }
        
        favoriteButton.setImage(UIImage(systemName: location.isFavorite ? "heart.fill" : "heart"), for: .normal)
        favoriteButton.tintColor = location.isFavorite ? .red : .gray
        favoriteButton.removeTarget(nil, action: nil, for: .allEvents)
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        
        selectionIndicator.isHidden = !isMultiSelecting
        selectionIndicator.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
        selectionIndicator.tintColor = isSelected ? .blue : .gray
    }
    
    @objc func toggleFavorite() {
        favoriteButtonTapped?()
    }
}

