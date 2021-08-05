//
//  ViewController.swift
//  Live Text Address
//
//  Created by Jackson Chung on 2/8/2021.
//

import AVFoundation
import MapKit
import UIKit

class ViewController: UIViewController {

    // search address
    private lazy var addressCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.region = MKCoordinateRegion(center: .init(latitude: 22.2975715, longitude: 114.1722044), // default location = Tsim Sha Tsui
                                              latitudinalMeters: 1000,
                                              longitudinalMeters: 1000)
        completer.delegate = self
        return completer
    } ()
    private var searchAddressResults = [MKLocalSearchCompletion]()
    private lazy var addressResultTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)

        return tableView
    }()

    // text to speech
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenAddress: String?
    private var autoSpeak = false

    // toolbar
    private lazy var keyboardToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: 320, height: 44))
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let searchBtn = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchDidTap))
        let cameraBtn = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraDidTap))
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDidTap))

        toolbar.items = [flexible, searchBtn, cameraBtn, doneBtn]
        toolbar.sizeToFit()

        return toolbar
    } ()

    private lazy var cameraToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: 320, height: 44))
        toolbar.items = [flexible, playBtn, searchBtn, keyboardBtn, doneBtn]
        toolbar.sizeToFit()

        return toolbar
    } ()

    private var flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    private var playBtn = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playDidTap))
    private var pauseBtn = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(playDidTap))
    private var searchBtn = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchDidTap))
    private let keyboardBtn = UIBarButtonItem(title: "Keyboard", style: .plain, target: self, action: #selector(keyboardDidTap))
    private let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDidTap))

    // textfield
    private lazy var searchAddressTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Search Address"
        textField.autocorrectionType = .no
        textField.returnKeyType = .search
        textField.clearButtonMode = .whileEditing

        return textField
    } ()

    private var cameraInputView: CameraKeyboard = {
        let view = CameraKeyboard()
        return view
    } ()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchAddressTextField.addTarget(self, action: #selector(addressDidChange), for: .valueChanged)
        searchAddressTextField.inputAccessoryView = keyboardToolbar

        view.addSubview(searchAddressTextField)
        view.addSubview(addressResultTableView)

        searchAddressTextField.translatesAutoresizingMaskIntoConstraints = false
        addressResultTableView.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 0
        NSLayoutConstraint.activate([
            searchAddressTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            searchAddressTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: margin),
            searchAddressTextField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -margin),
            searchAddressTextField.heightAnchor.constraint(equalToConstant: 48),

            addressResultTableView.topAnchor.constraint(equalTo: searchAddressTextField.bottomAnchor, constant: margin),
            addressResultTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            addressResultTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            addressResultTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        cameraInputView.textField = self.searchAddressTextField
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        searchAddressTextField.becomeFirstResponder()
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
        if autoSpeak, searchAddressTextField.text != lastSpokenAddress {
            speakInputedAddress()
        }
    }

    // MARK: search address
    @objc
    private func searchDidTap() {
        guard !addressCompleter.isSearching, let searchText = searchAddressTextField.text, !searchText.isEmpty else {
            return
        }

        addressCompleter.queryFragment = searchText
    }

    // MARK: text to speech
    @objc
    private func playDidTap() {
        if autoSpeak {
            autoSpeak = false
            synthesizer.stopSpeaking(at: .immediate)
            cameraToolbar.items = [flexible, playBtn, searchBtn, keyboardBtn, doneBtn]
        } else {
            autoSpeak = true
            speakInputedAddress()
            cameraToolbar.items = [flexible, pauseBtn, searchBtn, keyboardBtn, doneBtn]
        }
    }

    private func speakInputedAddress() {
        guard !synthesizer.isSpeaking else {
            return
        }

        if let speechText = searchAddressTextField.text, !speechText.isEmpty {
            lastSpokenAddress = speechText
            let speech = AVSpeechUtterance(string: speechText)
            speech.voice = .init(language: "zh-HK") // cantonese and english
            if #available(iOS 14.0, *) {
                speech.prefersAssistiveTechnologySettings = true
            }
            synthesizer.speak(speech)
        }
    }
}

extension ViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // show the top 10 results
        searchAddressResults = Array(completer.results.prefix(10))
        addressResultTableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchAddressResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchAddressResults[indexPath.row]

        let identifier = "searchResult"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle

        return cell
    }
}
