//
//  DetailPopupViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/11/24.
//

import UIKit
import PhotosUI

class DetailPopupViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, PHPickerViewControllerDelegate {
    var location: Location?
    var indexPath: IndexPath?
    var onSave: ((Location, IndexPath) -> Void)?
    
    private let textField = UITextField()
    private let memoField = UITextField()
    private let categoryPicker = UIPickerView()
    private let saveButton = UIButton()
    private let addImageButton = UIButton()
    private let imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let addCategoryButton = UIButton()
    private var images: [UIImage] = []
    private var categories: [(name: String, color: UIColor)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        loadData()
    }
    
    private func setupViews() {
        textField.placeholder = "별명"
        memoField.placeholder = "메모"
        
        textField.borderStyle = .roundedRect
        memoField.borderStyle = .roundedRect
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        saveButton.setTitle("저장", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        addImageButton.setTitle("사진 추가", for: .normal)
        addImageButton.setTitleColor(.white, for: .normal)
        addImageButton.backgroundColor = .systemGreen
        addImageButton.layer.cornerRadius = 10
        addImageButton.addTarget(self, action: #selector(addImageButtonTapped), for: .touchUpInside)
        addImageButton.contentHorizontalAlignment = .center
        addImageButton.titleLabel?.textAlignment = .center
        
        addCategoryButton.setTitle("카테고리 추가", for: .normal)
        addCategoryButton.setTitleColor(.white, for: .normal)
        addCategoryButton.backgroundColor = .systemOrange
        addCategoryButton.layer.cornerRadius = 10
        addCategoryButton.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
        
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        if let flowLayout = imagesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .horizontal
        }
        imagesCollectionView.backgroundColor = .white
        imagesCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        imagesCollectionView.layer.borderWidth = 1
        imagesCollectionView.layer.cornerRadius = 10
        
        let imageStackView = UIStackView(arrangedSubviews: [addImageButton, imagesCollectionView])
        imageStackView.axis = .horizontal
        imageStackView.spacing = 10
        imageStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [imageStackView, textField, memoField, categoryPicker, addCategoryButton, saveButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            addImageButton.widthAnchor.constraint(equalTo: addImageButton.heightAnchor, multiplier: 3/4),
            addImageButton.heightAnchor.constraint(equalToConstant: 100),
            
            imagesCollectionView.heightAnchor.constraint(equalToConstant: 100),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadData() {
        guard let location = location else { return }
        textField.text = location.nickname
        memoField.text = location.memo
        categories = CategoryManager.shared.getCategories()
        images = location.images
        imagesCollectionView.reloadData()
        categoryPicker.reloadAllComponents()
    }
    
    @objc private func saveButtonTapped() {
        guard var location = location, let indexPath = indexPath else { return }
        location.nickname = textField.text ?? ""
        location.memo = memoField.text ?? ""
        if categories.indices.contains(categoryPicker.selectedRow(inComponent: 0)) {
            location.category = categories[categoryPicker.selectedRow(inComponent: 0)].name
            location.categoryColor = categories[categoryPicker.selectedRow(inComponent: 0)].color
        }
        location.images = images
        
        onSave?(location, indexPath)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addImageButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0  // 0 means no limit
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @objc private func addCategoryButtonTapped() {
        let alertController = UIAlertController(title: "카테고리 추가", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "카테고리 이름"
        }
        alertController.addTextField { textField in
            textField.placeholder = "색상 (예: #FF0000)"
        }
        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alertController.textFields?[0].text,
                  let hex = alertController.textFields?[1].text,
                  !name.isEmpty, !hex.isEmpty else { return }
            let color = UIColor(hex: hex)
            CategoryManager.shared.addCategory(name: name, color: color)
            self.categories = CategoryManager.shared.getCategories()
            self.categoryPicker.reloadAllComponents()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self, let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.images.append(image)
                    self.imagesCollectionView.reloadData()
                }
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row].name
    }
}

extension DetailPopupViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        let imageView = UIImageView(image: images[indexPath.item])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        cell.contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
        return cell
    }
}
