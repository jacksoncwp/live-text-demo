//
//  CameraKeyboard.swift
//  Live Text Address
//
//  Created by Jackson Chung on 2/8/2021.
//

import AVFoundation
import UIKit
import Vision

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
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

    // MARK: keyboard
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

    @objc
    private func keyboardDidHide(_ notification: UIKit.Notification) {
        stopCamera()
    }

    // MARK: Camera
    public func startCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] response in
            guard let self = self else { return }
            if response {
                self.setupAndStartCaptureSession()
            } else {
                // TODO: ask for permission
            }
        }
    }

    private func stopCamera() {
        previewLayer?.removeFromSuperlayer()
        captureSession?.stopRunning()

        previewLayer = nil
        captureSession = nil
    }
    
    private func setupAndStartCaptureSession() {
        guard captureSession == nil else {
            print("capture session already exists")
            setupPreviewLayer()
            return
        }

        // start camera session will block the main thread, so we start in background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let captureSession = AVCaptureSession()
            self.captureSession = captureSession
            captureSession.beginConfiguration()

            captureSession.sessionPreset = .medium // medium quality is good enough for text recognition
            self.setupCameraInput(captureSession: captureSession)
            self.setupOutput(captureSession: captureSession)

            captureSession.commitConfiguration()
            captureSession.startRunning()

            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
        }
    }

    private func setupCameraInput(captureSession: AVCaptureSession) {
        // use back camera only
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }

        guard let backInput = try? AVCaptureDeviceInput(device: device) else {
            fatalError("could not create input device from back camera")
        }

        guard captureSession.canAddInput(backInput) else {
            fatalError("could not add back camera input to capture session")
        }

        captureSession.addInput(backInput)
    }

    private func setupPreviewLayer() {
        guard let captureSession = captureSession else {
            fatalError("could not get capture session")
        }

        guard previewLayer == nil else {
            print("preview layer already exists")
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = CGRect(origin: .zero, size: frame.size)
    }

    private func setupOutput(captureSession: AVCaptureSession) {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if captureSession.canAddOutput(videoOutput) == true {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }

        videoOutput.connections.first?.videoOrientation = .portrait
    }

    // MARK: text recognition
    private func detectText(buffer: CVPixelBuffer) {
        let request = VNRecognizeTextRequest(completionHandler: textRecognitionHandler)
          request.recognitionLanguages = ["en_US"]
          request.recognitionLevel = .accurate

          performDetection(request: request, buffer: buffer)
    }

    func performDetection(request: VNRecognizeTextRequest, buffer: CVPixelBuffer) {
        let requests = [request]
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform(requests)
            } catch let error {
                print("Error: \(error)")
            }
        }
    }

    private func textRecognitionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }

        let results = observations.compactMap { $0 as? VNRecognizedTextObservation }
        for result in results {
            for text in result.topCandidates(1) where text.confidence == 1 {
                // TODO: find the text in the middle
                print("recognized text: \(text.string) boundingBox: \(result.boundingBox)")
            }
        }
    }
}

extension CameraKeyboard: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        detectText(buffer: cvBuffer)
    }
}
