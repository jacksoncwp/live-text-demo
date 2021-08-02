//
//  CameraKeyboard.swift
//  Live Text Address
//
//  Created by Jackson Chung on 2/8/2021.
//

import AVFoundation
import UIKit

class CameraKeyboard: UIView {

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private lazy var aimContainerView: UIView = {
        let view = UIView(frame: self.frame)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alpha = 0.7

        return view
    } ()

    init() {
        super.init(frame: .init(x: 0, y: 0, width: 320, height: 300))
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        addSubview(aimContainerView)
        NSLayoutConstraint.activate([
            aimContainerView.topAnchor.constraint(equalTo: topAnchor),
            aimContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            aimContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            aimContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        addAimView()
    }

    private func addAimView() {
        let upperView = UIView()
        let lowerView = UIView()
        let leftView = UIView()
        let rightView = UIView()

        let views: [UIView] = [upperView, lowerView, leftView, rightView]
        views.forEach {
            $0.backgroundColor = UIColor(red: 0.00, green: 0.53, blue: 0.75, alpha: 1.00)
            $0.translatesAutoresizingMaskIntoConstraints = false
            aimContainerView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            upperView.bottomAnchor.constraint(equalTo: aimContainerView.centerYAnchor, constant: -4),
            upperView.centerXAnchor.constraint(equalTo: aimContainerView.centerXAnchor),
            upperView.heightAnchor.constraint(equalToConstant: 16),
            upperView.widthAnchor.constraint(equalToConstant: 2),

            lowerView.topAnchor.constraint(equalTo: aimContainerView.centerYAnchor, constant: 4),
            lowerView.centerXAnchor.constraint(equalTo: aimContainerView.centerXAnchor),
            lowerView.heightAnchor.constraint(equalToConstant: 16),
            lowerView.widthAnchor.constraint(equalToConstant: 2),

            leftView.trailingAnchor.constraint(equalTo: aimContainerView.centerXAnchor, constant: -4),
            leftView.centerYAnchor.constraint(equalTo: aimContainerView.centerYAnchor),
            leftView.heightAnchor.constraint(equalToConstant: 2),
            leftView.widthAnchor.constraint(equalToConstant: 16),

            rightView.leadingAnchor.constraint(equalTo: aimContainerView.centerXAnchor, constant: 4),
            rightView.centerYAnchor.constraint(equalTo: aimContainerView.centerYAnchor),
            rightView.heightAnchor.constraint(equalToConstant: 2),
            rightView.widthAnchor.constraint(equalToConstant: 16),
        ])
    }

    @objc
    private func keyboardWillShow(_ notification: UIKit.Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }
        frame = .init(origin: .zero, size: keyboardFrame.size)
    }

    public func startCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] response in
            guard let self = self else { return }
            if response {
                self.setupAndStartCaptureSession()
            } else {

            }
        }
    }

    public func stopCamera() {
        previewLayer?.removeFromSuperlayer()
        captureSession?.stopRunning()
    }

    //MARK:- Camera Setup
    private func setupAndStartCaptureSession() {
        // start camera session will block the main thread, so we start in background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let captureSession = AVCaptureSession()
            self.captureSession = captureSession
            captureSession.beginConfiguration()

            //session specific configuration
            if captureSession.canSetSessionPreset(.photo) {
                captureSession.sessionPreset = .photo
            } else if captureSession.canSetSessionPreset(.high) {
                captureSession.sessionPreset = .high
            } else {
                captureSession.sessionPreset = .medium
            }
            self.setupCameraInput()


            captureSession.commitConfiguration()
            captureSession.startRunning()

            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
        }
    }

    private func setupCameraInput() {
        // use back camera only
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }

        guard let backInput = try? AVCaptureDeviceInput(device: device) else {
            fatalError("could not create input device from back camera")
        }

        guard let captureSession = captureSession, captureSession.canAddInput(backInput) else {
            fatalError("could not add back camera input to capture session")
        }

        captureSession.addInput(backInput)
    }

    private func setupPreviewLayer() {
        guard let captureSession = captureSession else {
            fatalError("could not get capture session")
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = CGRect(origin: .zero, size: frame.size)
    }
}
