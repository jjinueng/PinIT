//
//  PlaceDetailViewController.swift
//  PinIT
//
//  Created by 김지윤 on 6/5/24.
//

import UIKit
import CoreLocation

class PlaceDetailViewController: UIViewController {
    var place: (location: CLLocation, address: String)?
    var nicknameTextField: UITextField!
    var descriptionTextView: UITextView!
    var categoryTextField: UITextField!
    var saveButton: UIButton!

    var onSave: ((String, String, String, CLLocation) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        view.backgroundColor = .white

        let nicknameLabel = UILabel()
        nicknameLabel.text = "별명"
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nicknameLabel)

        nicknameTextField = UITextField()
        nicknameTextField.borderStyle = .roundedRect
        nicknameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nicknameTextField)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "메모"
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)

        descriptionTextView = UITextView()
        descriptionTextView.layer.borderColor = UIColor.gray.cgColor
        descriptionTextView.layer.borderWidth = 1.0
        descriptionTextView.layer.cornerRadius = 5.0
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionTextView)

        let categoryLabel = UILabel()
        categoryLabel.text = "카테고리"
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryLabel)

        categoryTextField = UITextField()
        categoryTextField.borderStyle = .roundedRect
        categoryTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryTextField)

        saveButton = UIButton(type: .system)
        saveButton.setTitle("저장학", for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            nicknameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nicknameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nicknameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nicknameTextField.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 10),
            nicknameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nicknameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            descriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 100),

            categoryLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            categoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categoryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            categoryTextField.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 10),
            categoryTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categoryTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            saveButton.topAnchor.constraint(equalTo: categoryTextField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func saveButtonTapped() {
        guard let place = place else { return }
        let nickname = nicknameTextField.text ?? ""
        let description = descriptionTextView.text ?? ""
        let category = categoryTextField.text ?? ""
        onSave?(nickname, description, category, place.location)
        dismiss(animated: true, completion: nil)
    }
}
