//
//  ViewController.swift
//  Live Text Address
//
//  Created by Jackson Chung on 2/8/2021.
//

import SnapKit
import UIKit

class ViewController: UIViewController {

    private lazy var searchAddressTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Search Address"
        textField.autocorrectionType = .no
        textField.returnKeyType = .search

        return textField
    } ()

    private lazy var keyboardToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let cameraBtn = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraDidTap))
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDidTap))

        toolbar.items = [flexible, cameraBtn, doneBtn]
        toolbar.sizeToFit()

        return toolbar
    } ()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        view.addSubview(searchAddressTextField)
        searchAddressTextField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        searchAddressTextField.inputAccessoryView = keyboardToolbar
    }

    @objc
    private func cameraDidTap() {
        // TODO: show camera
    }

    @objc
    private func doneDidTap() {
        searchAddressTextField.resignFirstResponder()
    }
}

