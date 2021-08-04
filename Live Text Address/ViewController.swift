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
        textField.clearButtonMode = .whileEditing

        return textField
    } ()

    private lazy var keyboardToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: 320, height: 44))
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let cameraBtn = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraDidTap))
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDidTap))

        toolbar.items = [flexible, cameraBtn, doneBtn]
        toolbar.sizeToFit()

        return toolbar
    } ()

    private lazy var cameraToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: 320, height: 44))
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let keyboardBtn = UIBarButtonItem(title: "Keyboard", style: .plain, target: self, action: #selector(keyboardDidTap))
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDidTap))

        toolbar.items = [flexible, keyboardBtn, doneBtn]
        toolbar.sizeToFit()

        return toolbar
    } ()

    private var cameraInputView: CameraKeyboard = {
        let view = CameraKeyboard()
        return view
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
        searchAddressTextField.addTarget(self, action: #selector(addressDidChange), for: .valueChanged)
        searchAddressTextField.inputAccessoryView = keyboardToolbar

        cameraInputView.textField = self.searchAddressTextField
    }

    @objc
    private func cameraDidTap() {
        searchAddressTextField.inputAccessoryView = cameraToolbar
        searchAddressTextField.inputView = cameraInputView
        cameraInputView.startCamera()
        searchAddressTextField.reloadInputViews()
    }

    @objc
    private func keyboardDidTap() {
        searchAddressTextField.inputAccessoryView = keyboardToolbar
        searchAddressTextField.inputView = nil
        searchAddressTextField.reloadInputViews()
    }

    @objc
    private func doneDidTap() {
        searchAddressTextField.resignFirstResponder()
        keyboardDidTap()
    }

    @objc
    private func addressDidChange() {
        print("search address: \(searchAddressTextField.text ?? "")")
    }
}
