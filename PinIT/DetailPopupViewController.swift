//
//  DetailPopupViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/11/24.
//

import UIKit
import PhotosUI
import NMapsMap

class DetailPopupViewController: UIViewController, UIPickerViewDelegate, PHPickerViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    var location: Location?
    var indexPath: IndexPath?
    var onSave: ((Location?, IndexPath) -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let mapView = NMFMapView()
    private let buildingNameLabel = UILabel()
    private let addressLabel = UILabel()
    private let textField = UITextField()
    private let memoField = UITextView()
    private let saveButton = UIButton()
    private let addImageButton = UIButton()
    private let addImageCountLabel = UILabel()
    private let imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let categoryButton = UIButton(type: .system)
    private var images: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupViews()
        setupMapView()
        loadSavedLocationsData()
        updateImageCollectionViewVisibility()
        
        imagesCollectionView.dragDelegate = self
        imagesCollectionView.dropDelegate = self
        imagesCollectionView.dragInteractionEnabled = true
    }
    
    private func setupViews() {
        // ScrollView and ContentView setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Delete Button
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)
        
        // Edit Button
        editButton.setTitle("수정", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editButton)
        
        // Building Name Label
        buildingNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        buildingNameLabel.textAlignment = .left
        
        // Category Button
        categoryButton.setTitle("카테고리", for: .normal)
        categoryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        categoryButton.setTitleColor(.black, for: .normal)
        categoryButton.titleLabel?.font = buildingNameLabel.font
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        categoryButton.isUserInteractionEnabled = false // 기본적으로 수정 불가 상태로 설정
        view.addSubview(categoryButton)
        
        // Address Label
        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textAlignment = .left
        addressLabel.textColor = .gray
        
        // Add Image Button
        addImageButton.setTitle("", for: .normal)
        addImageButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        addImageButton.tintColor = .gray
        addImageButton.layer.cornerRadius = 10
        addImageButton.layer.borderWidth = 1
        addImageButton.layer.borderColor = UIColor.gray.cgColor
        addImageButton.addTarget(self, action: #selector(addImageButtonTapped), for: .touchUpInside)
        addImageButton.contentHorizontalAlignment = .center
        addImageButton.titleLabel?.textAlignment = .center
        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        addImageButton.isHidden = true  // 기본적으로 숨김
        
        addImageCountLabel.text = "0/10"
        addImageCountLabel.textAlignment = .center
        addImageCountLabel.font = UIFont.systemFont(ofSize: 12)
        addImageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        addImageCountLabel.textColor = UIColor.gray
        addImageButton.addSubview(addImageCountLabel)
        
        // Nickname Label
        let nicknameLabel = UILabel()
        nicknameLabel.text = "별명"
        nicknameLabel.font = UIFont.systemFont(ofSize: 16)
        nicknameLabel.textAlignment = .left
        
        // Memo Label
        let memoLabel = UILabel()
        memoLabel.text = "메모"
        memoLabel.font = UIFont.systemFont(ofSize: 16)
        memoLabel.textAlignment = .left
        
        // TextField
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 10
        textField.setPadding(left: 10, right: 10)
        textField.isUserInteractionEnabled = false  // 기본적으로 입력 불가 상태로 설정
        
        // MemoField
        memoField.layer.borderWidth = 1
        memoField.layer.borderColor = UIColor.lightGray.cgColor
        memoField.layer.cornerRadius = 10
        memoField.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        memoField.font = UIFont.systemFont(ofSize: 16)
        memoField.isEditable = false  // 기본적으로 입력 불가 상태로 설정
        
        // Images Collection View
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        if let flowLayout = imagesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .horizontal
        }
        imagesCollectionView.backgroundColor = .clear
        
        // Stack Views
        let imageStackView = UIStackView(arrangedSubviews: [addImageButton, imagesCollectionView])
        imageStackView.axis = .horizontal
        imageStackView.spacing = 10
        imageStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let nicknameStackView = UIStackView(arrangedSubviews: [nicknameLabel, textField])
        nicknameStackView.axis = .vertical
        nicknameStackView.spacing = 5
        nicknameStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let memoStackView = UIStackView(arrangedSubviews: [memoLabel, memoField])
        memoStackView.axis = .vertical
        memoStackView.spacing = 5
        memoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let buildingStackView = UIStackView(arrangedSubviews: [buildingNameLabel, categoryButton])
        buildingStackView.axis = .horizontal
        buildingStackView.spacing = 10
        buildingStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [buildingStackView, addressLabel, imageStackView, nicknameStackView, memoStackView])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            editButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            addImageButton.heightAnchor.constraint(equalToConstant: 100),
            addImageButton.widthAnchor.constraint(equalTo: addImageButton.heightAnchor), // Ensure addImageButton is square
            addImageCountLabel.centerXAnchor.constraint(equalTo: addImageButton.centerXAnchor),
            addImageCountLabel.topAnchor.constraint(equalTo: addImageButton.imageView?.bottomAnchor ?? addImageButton.bottomAnchor, constant: 5),
            
            imagesCollectionView.heightAnchor.constraint(equalTo: addImageButton.heightAnchor),
            imagesCollectionView.leadingAnchor.constraint(equalTo: addImageButton.trailingAnchor, constant: 10),
            imagesCollectionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            imagesCollectionView.topAnchor.constraint(equalTo: addImageButton.topAnchor),
            imagesCollectionView.bottomAnchor.constraint(equalTo: addImageButton.bottomAnchor),
            
            memoField.heightAnchor.constraint(equalToConstant: 150),
            
            categoryButton.widthAnchor.constraint(equalToConstant: 100), // 버튼의 너비를 설정
            categoryButton.heightAnchor.constraint(equalToConstant: 30),
            categoryButton.topAnchor.constraint(equalTo: buildingNameLabel.topAnchor),
        ])
    }
    
    private func setupMapView() {
        guard var location = location else { return }
        let coord = NMGLatLng(lat: location.latitude, lng: location.longitude)
        mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))
        
        let marker = NMFMarker()
        marker.position = coord
        marker.iconTintColor = .red
        marker.width = 30
        marker.height = 39
        marker.mapView = mapView
        
        mapView.positionMode = .disabled
        mapView.touchDelegate = self
        mapView.addCameraDelegate(delegate: self)
        
        buildingNameLabel.text = location.buildingName ?? ""
        addressLabel.text = location.fullAddress ?? ""
    }
    
    private func loadSavedLocationsData() {
        guard var location = location else { return }
        let defaults = UserDefaults.standard
        let savedLocations = defaults.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        
        if let savedLocation = savedLocations.first(where: {
            guard let lat = $0["latitude"] as? Double, let lng = $0["longitude"] as? Double else { return false }
            return lat == location.latitude && lng == location.longitude
        }) {
            textField.text = savedLocation["nickname"] as? String
            memoField.text = savedLocation["memo"] as? String
            if let savedImageData = savedLocation["images"] as? [Data] {
                images = savedImageData.compactMap { UIImage(data: $0) }
                updateImageCount()
                imagesCollectionView.reloadData()
            }
            if let category = savedLocation["category"] as? String, let categoryColor = savedLocation["categoryColor"] as? String {
                location.category = category
                location.categoryColor = UIColor(hex: categoryColor)
                categoryButton.setTitle(category, for: .normal)
            }
            if savedLocation["category"] == nil {
                categoryButton.setTitle("카테고리", for: .normal)
            }
        }
    }
    
    @objc private func saveButtonTapped() {
        guard var location = location, let indexPath = indexPath else { return }
        location.nickname = textField.text ?? ""
        location.memo = memoField.text ?? ""
        location.images = images
        
        // 저장하기 전에 데이터를 출력해 확인
        print("Saving Location: \(location)")
        
        onSave?(location, indexPath)
        
        let defaults = UserDefaults.standard
        var savedLocations = defaults.array(forKey: "savedMarkerLocations") as? [[String: Any]] ?? []
        
        let locationDict: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "isFavorite": location.isFavorite,
            "buildingName": location.buildingName ?? "",
            "fullAddress": location.fullAddress ?? "",
            "createdAt": location.createdAt.timeIntervalSince1970,
            "nickname": location.nickname ?? "",
            "memo": location.memo ?? "",
            "category": location.category ?? "",
            "categoryColor": location.categoryColor?.hexString ?? "#FFFFFF",
            "images": location.images.compactMap { $0.jpegData(compressionQuality: 1.0) }
        ]
        
        // 기존 위치를 찾아서 업데이트 또는 새로 추가
        if let existingIndex = savedLocations.firstIndex(where: { ($0["latitude"] as? Double) == location.latitude && ($0["longitude"] as? Double) == location.longitude }) {
            savedLocations[existingIndex] = locationDict
        } else {
            savedLocations.append(locationDict)
        }
        
        defaults.set(savedLocations, forKey: "savedMarkerLocations")
        
        // UserDefaults에 저장 후 다시 불러오기
        if let listVC = presentingViewController as? ListViewController {
            listVC.loadVisitedPlaces()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func deleteButtonTapped() {
        // 삭제 버튼을 눌렀을 때의 동작을 구현합니다.
        let alert = UIAlertController(title: "삭제 확인", message: "이 위치를 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
            guard let self = self, let location = self.location, let indexPath = self.indexPath else { return }
            self.onSave?(nil, indexPath)
            
            let defaults = UserDefaults.standard
            let locationKey = "\(location.latitude)_\(location.longitude)"
            defaults.removeObject(forKey: "\(locationKey)_nickname")
            defaults.removeObject(forKey: "\(locationKey)_memo")
            defaults.removeObject(forKey: "\(locationKey)_images")
            
            self.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func editButtonTapped() {
        // 수정 버튼을 눌렀을 때의 동작을 구현합니다.
        textField.isUserInteractionEnabled = true
        memoField.isEditable = true
        addImageButton.isHidden = false  // 이미지 추가 버튼 표시
        imagesCollectionView.isHidden = false
        categoryButton.isUserInteractionEnabled = true // 카테고리 버튼 활성화
        
        // 각 셀의 삭제 버튼을 표시
        for case let cell as ImageCell in imagesCollectionView.visibleCells {
            cell.deleteButton.isHidden = false
        }
        
        // 수정 모드로 전환 시, 수정 완료 버튼으로 변경
        editButton.setTitle("완료", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.removeTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(saveEdits), for: .touchUpInside)
    }
    
    @objc private func saveEdits() {
        // 수정 완료 버튼을 눌렀을 때의 동작을 구현합니다.
        textField.isUserInteractionEnabled = false
        memoField.isEditable = false
        addImageButton.isHidden = true  // 이미지 추가 버튼 숨김
        categoryButton.isUserInteractionEnabled = false // 카테고리 버튼 비활성화
        
        // 각 셀의 삭제 버튼을 숨김
        for case let cell as ImageCell in imagesCollectionView.visibleCells {
            cell.deleteButton.isHidden = true
        }
        
        if images.isEmpty {
            imagesCollectionView.isHidden = true
        }
        
        // 콜렉션 뷰 가시성 업데이트
        updateImageCollectionViewVisibility()
        
        // 수정 완료 후, UserDefaults에 저장
        saveButtonTapped()
        
        // 수정 완료 후, 다시 수정 버튼으로 변경
        editButton.setTitle("수정", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.removeTarget(self, action: #selector(saveEdits), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    
    @objc private func categoryButtonTapped() {
        let categoryDataSource = ["음식점", "카페", "관광지", "숙소", "핫플"]
        let alert = UIAlertController(title: "카테고리 선택", message: nil, preferredStyle: .actionSheet)
        
        for category in categoryDataSource {
            let action = UIAlertAction(title: category, style: .default) { [weak self] _ in
                self?.categorySelected(category)
            }
            alert.addAction(action)
        }
        
        let deleteAction = UIAlertAction(title: "카테고리 삭제", style: .destructive) { [weak self] _ in
            self?.deleteCategory()
        }
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

    private func deleteCategory() {
        location?.category = ""
        location?.categoryColor = .clear
        categoryButton.setTitle("카테고리", for: .normal)
    }

    
    private func categorySelected(_ category: String) {
        var categoryColor: UIColor
        
        switch category {
        case "음식점":
            categoryColor = .red
        case "카페":
            categoryColor = .orange
        case "관광지":
            categoryColor = .yellow
        case "숙소":
            categoryColor = .blue
        case "핫플":
            categoryColor = .purple
        default:
            categoryColor = .black
        }
        
        location?.category = category
        location?.categoryColor = categoryColor
        
        // 카테고리 버튼 타이틀과 색상 업데이트
        categoryButton.setTitle(category, for: .normal)
    }
    
    @objc private func addImageButtonTapped() {
        guard images.count < 10 else {
            let alert = UIAlertController(title: "알림", message: "사진은 최대 10장까지 추가할 수 있습니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "사진 추가", message: "사진을 추가할 방법을 선택하세요.", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            self?.presentCamera()
        }
        let libraryAction = UIAlertAction(title: "사진 앨범", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "카메라 사용 불가", message: "카메라를 사용할 수 없습니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func presentPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10 - images.count // Allow selection up to 10 images
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self, let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.images.append(image)
                    self.updateImageCount()
                    self.imagesCollectionView.reloadData()
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            images.append(image)
            updateImageCount()
            imagesCollectionView.reloadData()
        }
    }
    
    private func updateImageCount() {
        addImageCountLabel.text = "\(images.count)/10"
    }
    
    private func updateImageCollectionViewVisibility() {
        imagesCollectionView.isHidden = !images.isEmpty ? false : !editButton.currentTitle!.elementsEqual("완료")
    }
    
    // UICollectionViewDataSource methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.item]
        cell.deleteButton.tag = indexPath.item
        cell.deleteButton.isHidden = !textField.isUserInteractionEnabled
        cell.deleteButton.addTarget(self, action: #selector(deleteImage(_:)), for: .touchUpInside)
        cell.representativeLabel.isHidden = indexPath.item != 0
        return cell
    }
    
    // UICollectionViewDragDelegate
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard textField.isUserInteractionEnabled else { return [] }
        let item = self.images[indexPath.row]
        let itemProvider = NSItemProvider(object: item)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    // UICollectionViewDropDelegate
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // If there is no destination index path, drop at the end of the section
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndexPath = IndexPath(row: row - 1, section: 0)
        }
        
        collectionView.performBatchUpdates({
            for item in coordinator.items {
                if let sourceIndexPath = item.sourceIndexPath {
                    let movedItem = self.images.remove(at: sourceIndexPath.item)
                    self.images.insert(movedItem, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }
            }
        }, completion: { _ in
            collectionView.reloadData()
        })
        coordinator.drop(coordinator.items.first!.dragItem, toItemAt: destinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    @objc private func deleteImage(_ sender: UIButton) {
        images.remove(at: sender.tag)
        updateImageCount()
        imagesCollectionView.reloadData()
        updateImageCollectionViewVisibility() // 업데이트 후 가시성 체크
    }
    
    // UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100) // Same height as addImageButton
    }
}

extension DetailPopupViewController: NMFMapViewTouchDelegate, NMFMapViewCameraDelegate {
    func mapView(_ mapView: NMFMapView, didTap map: NMGLatLng) {
        // 지도 터치 이벤트를 비활성화합니다.
    }
    
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        guard let location = location else { return }
        let coord = NMGLatLng(lat: location.latitude, lng: location.longitude)
        if mapView.cameraPosition.target != coord {
            mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))
        }
    }
}

class ImageCell: UICollectionViewCell {
    let imageView = UIImageView()
    let deleteButton = UIButton()
    let representativeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isHidden = true
        contentView.addSubview(deleteButton)
        
        representativeLabel.text = "대표사진"
        representativeLabel.textColor = .white
        representativeLabel.backgroundColor = .black.withAlphaComponent(0.5)
        representativeLabel.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        representativeLabel.layer.cornerRadius = 10
        representativeLabel.clipsToBounds = true
        representativeLabel.textAlignment = .center
        representativeLabel.font = UIFont.boldSystemFont(ofSize: 12)
        representativeLabel.translatesAutoresizingMaskIntoConstraints = false
        representativeLabel.isHidden = true  // 기본적으로 숨김
        contentView.addSubview(representativeLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20),
            representativeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            representativeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            representativeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            representativeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}

extension UITextField {
    func setPadding(left: CGFloat, right: CGFloat) {
        let paddingViewLeft = UIView(frame: CGRect(x: 0, y: 0, width: left, height: self.frame.height))
        self.leftView = paddingViewLeft
        self.leftViewMode = .always
        
        let paddingViewRight = UIView(frame: CGRect(x: 0, y: 0, width: right, height: self.frame.height))
        self.rightView = paddingViewRight
        self.rightViewMode = .always
    }
}
