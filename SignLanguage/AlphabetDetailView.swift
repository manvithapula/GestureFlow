//
//  AlphabetDetailView.swift
//  newProj
//
//  Created by admin@33 on 29/01/25.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML

struct AlphabetDetailView: View {
    let letter: String
    @State private var showCamera = false
    @State private var isCompleted = false
    
    var body: some View {
        VStack {
            if isCompleted {
                CompletionView(letter: letter)
            } else {
                if !showCamera {
                    LearningView(letter: letter, showCamera: $showCamera)
                } else {
                    CameraView(letter: letter, isCompleted: $isCompleted)
                }
            }
        }
        .navigationTitle("Learn \(letter)")
    }
}

struct CameraView: View {
    let letter: String
    @Binding var isCompleted: Bool
    @StateObject private var camera = CameraController()
    @State private var recognizedLetter: String = ""
    @State private var confidence: Float = 0.0
    @State private var consecutiveCorrect = 0
    private let requiredConsecutive = 3
    @State private var showHelp = false
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Sign: \(letter)")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: { showHelp.toggle() }) {
                    Text(showHelp ? "Hide Help" : "Show Help")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                if showHelp {
                    Image("ASL_\(letter)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .padding(.top, 20)
                }
                
                Spacer()
                
                Text(recognizedLetter.isEmpty ? "Show hand sign" : recognizedLetter)
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            camera.startCapture()
            camera.onRecognition = { label, conf in
                recognizedLetter = label
                confidence = conf
                
                if label == letter && conf >= 0.85 {
                    consecutiveCorrect += 1
                    if consecutiveCorrect >= requiredConsecutive {
                        DispatchQueue.main.async {
                            isCompleted = true
                        }
                    }
                } else {
                    consecutiveCorrect = 0
                }
            }
        }
        .onDisappear {
            camera.stopCapture()
        }
    }
}

class CameraController: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var model: ASLAlphabetsPoseClassifier_1?
    var onRecognition: ((String, Float) -> Void)?
    
    private var predictionHistory: [(String, Float)] = []
    private let historyLength = 10
    private let predictionInterval: TimeInterval = 0.2
    private var confidenceThreshold: Float = 0.8
    private var stabilityCounter = 0
    private var lastStablePrediction: String?
    
    private var lastPredictionTime: Date? = Date()
    
    private let jointOrder: [VNHumanHandPoseObservation.JointName] = [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexMCP, .indexPIP, .indexDIP, .indexTip,
        .middleMCP, .middlePIP, .middleDIP, .middleTip,
        .ringMCP, .ringPIP, .ringDIP, .ringTip,
        .littleMCP, .littlePIP, .littleDIP, .littleTip
    ]
    
    override init() {
        super.init()
        setupCamera()
        setupModel()
        handPoseRequest.maximumHandCount = 1
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .medium  // Changed from .high to .medium
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }
        
        try? device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
        device.unlockForConfiguration()
        
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue", qos: .userInteractive))
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        // Configure output connection
        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isEnabled = true
        }
    }
    
    func startCapture() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            self?.lastPredictionTime = Date()  // Initialize the timestamp
        }
    }
    
    private func setupModel() {
        do {
            model = try ASLAlphabetsPoseClassifier_1(configuration: MLModelConfiguration())
        } catch {
            print("Error loading model: \(error)")
        }
    }
    
//    func startCapture() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            if !self.captureSession.isRunning {
//                self.captureSession.startRunning()
//            }
//        }
//    }
    
    func stopCapture() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func extractFeatures(from observation: VNHumanHandPoseObservation) throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [1, 3, 21] as [NSNumber], dataType: .float32)
        var validPoints = 0
        
        // Reduced base confidence threshold for initial hand detection
        guard observation.confidence > 0.3 else {
            throw NSError(domain: "HandPose",
                         code: 1,
                         userInfo: ["NSLocalizedDescriptionKey": "Low overall hand confidence"])
        }
        
        // Get all reference points first
        let referencePoints: [(point: CGPoint?, confidence: Float, joint: VNHumanHandPoseObservation.JointName)] = [
            (try? observation.recognizedPoint(.wrist).location,
             (try? observation.recognizedPoint(.wrist).confidence) ?? 0, .wrist),
            (try? observation.recognizedPoint(.indexMCP).location,
             (try? observation.recognizedPoint(.indexMCP).confidence) ?? 0, .indexMCP),
            (try? observation.recognizedPoint(.middleMCP).location,
             (try? observation.recognizedPoint(.middleMCP).confidence) ?? 0, .middleMCP),
            (try? observation.recognizedPoint(.littleMCP).location,
             (try? observation.recognizedPoint(.littleMCP).confidence) ?? 0, .littleMCP)
        ]
        
        // Check if we have enough valid reference points
        let validReferencePoints = referencePoints.filter { $0.confidence > 0.3 }
        guard validReferencePoints.count >= 3,
              let wristPoint = referencePoints[0].point,
              let indexMCP = referencePoints[1].point,
              let pinkyMCP = referencePoints[3].point else {
            throw NSError(domain: "HandPose",
                         code: 1,
                         userInfo: ["NSLocalizedDescriptionKey": "Reference points not detected with sufficient confidence"])
        }
        
        // Calculate hand metrics with available points
        let handNormal = calculateHandPlane(wrist: wristPoint, index: indexMCP, pinky: pinkyMCP)
        
        let handWidth = hypot(indexMCP.x - pinkyMCP.x, indexMCP.y - pinkyMCP.y)
        guard handWidth > 0.01 else {
            throw NSError(domain: "HandPose",
                         code: 1,
                         userInfo: ["NSLocalizedDescriptionKey": "Hand width too small"])
        }
        
        let centerX = (indexMCP.x + pinkyMCP.x) / 2
        let centerY = (indexMCP.y + pinkyMCP.y) / 2
        
        // Process all joints with more lenient confidence threshold
        for (index, joint) in jointOrder.enumerated() {
            if let point = try? observation.recognizedPoint(joint),
               point.confidence > 0.2 { // Reduced confidence threshold for individual points
                validPoints += 1
                
                let normalizedPoint = normalizePoint(point.location,
                                                   center: CGPoint(x: centerX, y: centerY),
                                                   handWidth: handWidth,
                                                   normal: handNormal)
                
                array[[0, 0, index] as [NSNumber]] = normalizedPoint.x as NSNumber
                array[[0, 1, index] as [NSNumber]] = normalizedPoint.y as NSNumber
                array[[0, 2, index] as [NSNumber]] = point.confidence as NSNumber
            } else {
                // For missing points, use interpolated values if possible
                if let interpolated = interpolatePoint(for: joint,
                                                     observation: observation,
                                                     center: CGPoint(x: centerX, y: centerY)) {
                    array[[0, 0, index] as [NSNumber]] = interpolated.x as NSNumber
                    array[[0, 1, index] as [NSNumber]] = interpolated.y as NSNumber
                    array[[0, 2, index] as [NSNumber]] = 0.2 as NSNumber // Low confidence for interpolated points
                } else {
                    array[[0, 0, index] as [NSNumber]] = 0.0
                    array[[0, 1, index] as [NSNumber]] = 0.0
                    array[[0, 2, index] as [NSNumber]] = 0.0
                }
            }
        }
        
        // Reduced minimum valid points requirement
        guard validPoints >= 12 else { // Changed from 16 to 12
            throw NSError(domain: "HandPose",
                         code: 2,
                         userInfo: ["NSLocalizedDescriptionKey": "Insufficient valid points: \(validPoints)"])
        }
        
        return array
    }
    
    private func interpolatePoint(for joint: VNHumanHandPoseObservation.JointName,
                                observation: VNHumanHandPoseObservation,
                                center: CGPoint) -> (x: Float, y: Float)? {
        // Simple interpolation based on nearby points
        switch joint {
        case .indexDIP:
            if let pip = try? observation.recognizedPoint(.indexPIP),
               let tip = try? observation.recognizedPoint(.indexTip),
               pip.confidence > 0.3, tip.confidence > 0.3 {
                return (
                    Float((pip.location.x + tip.location.x) / 2 - center.x),
                    Float((pip.location.y + tip.location.y) / 2 - center.y)
                )
            }
        case .middleDIP:
            if let pip = try? observation.recognizedPoint(.middlePIP),
               let tip = try? observation.recognizedPoint(.middleTip),
               pip.confidence > 0.3, tip.confidence > 0.3 {
                return (
                    Float((pip.location.x + tip.location.x) / 2 - center.x),
                    Float((pip.location.y + tip.location.y) / 2 - center.y)
                )
            }
        // Add more cases for other joints as needed
        default:
            return nil
        }
        return nil
    }
    
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )
        
        do {
            try requestHandler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                print("No hand detected")
                return
            }
            
            let features = try self.extractFeatures(from: observation)
            try self.classifyPose(features)
            
        } catch let error as NSError {
            // More detailed error handling
            if error.domain == "HandPose" {
                // These are expected errors during normal operation
                if error.code == 1 {
                    // Reference points not detected - this is common when hand is moving
                    print("Hand detection issue: \(error.userInfo["NSLocalizedDescriptionKey"] as? String ?? "Unknown error")")
                } else if error.code == 2 {
                    // Insufficient valid points - also common during movement
                    print("Point detection issue: \(error.userInfo["NSLocalizedDescriptionKey"] as? String ?? "Unknown error")")
                }
            } else {
                // Unexpected errors should be logged for debugging
                print("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
    
    private func calculateHandPlane(wrist: CGPoint, index: CGPoint, pinky: CGPoint) -> SIMD3<Float> {
        let v1 = SIMD3<Float>(Float(index.x - wrist.x),
                             Float(index.y - wrist.y),
                             0)
        let v2 = SIMD3<Float>(Float(pinky.x - wrist.x),
                             Float(pinky.y - wrist.y),
                             0)
        return normalize(cross(v1, v2))
    }
    
    private func normalizePoint(_ point: CGPoint, center: CGPoint, handWidth: CGFloat, normal: SIMD3<Float>) -> (x: Float, y: Float) {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        let normalizedX = Float(dx / handWidth)
        let normalizedY = Float(dy / handWidth)
        
        // Apply perspective correction
        let correctedX = normalizedX * (1 + abs(normal.z) * 0.2)
        let correctedY = normalizedY * (1 + abs(normal.z) * 0.2)
        
        return (correctedX, correctedY)
    }
    
    private func classifyPose(_ features: MLMultiArray) throws {
        guard let model = model,
              let lastTime = lastPredictionTime,
              Date().timeIntervalSince(lastTime) >= predictionInterval else { return }
        
        let prediction = try model.prediction(poses: features)
        let sortedPredictions = prediction.labelProbabilities.sorted { $0.value > $1.value }
        
        guard let topPrediction = sortedPredictions.first,
              Float(topPrediction.value) > confidenceThreshold else {
            stabilityCounter = 0
            return
        }
        
        // The prediction key is now directly the letter (A-Z)
        let predictedLetter = topPrediction.key
        let confidence = Float(topPrediction.value)
        
        predictionHistory.append((predictedLetter, confidence))
        if predictionHistory.count > historyLength {
            predictionHistory.removeFirst()
        }
        
        let groupedPredictions = Dictionary(grouping: predictionHistory, by: { $0.0 })
        if let mostFrequent = groupedPredictions.max(by: { $0.value.count < $1.value.count }),
           mostFrequent.value.count >= 5 {
            
            let avgConfidence = mostFrequent.value.reduce(0) { $0 + $1.1 } / Float(mostFrequent.value.count)
            
            if avgConfidence > 0.85 {
                if mostFrequent.key == lastStablePrediction {
                    stabilityCounter += 1
                } else {
                    stabilityCounter = 0
                }
                
                lastStablePrediction = mostFrequent.key
                
                if stabilityCounter >= 2 {
                    DispatchQueue.main.async {
                        self.onRecognition?(mostFrequent.key, avgConfidence)
                    }
                }
            }
        }
        
        lastPredictionTime = Date()
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
}

struct CameraPreview: UIViewRepresentable {
    let camera: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct LearningView: View {
    let letter: String
    @Binding var showCamera: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image("ASL_\(letter)")
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(15)
                .shadow(radius: 10)
            
            Text("Learn the sign for '\(letter)'")
                .font(.title2)
                .bold()
            
            Button(action: { showCamera = true }) {
                Text("Start Practice")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                             startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct CompletionView: View {
    let letter: String
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text("Great Job!")
                .font(.largeTitle)
                .bold()
            
            Text("You've mastered the sign for '\(letter)'")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: ContentView()) {
                Text("Back to Alphabet")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
    }
}

let ASL_LABELS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
                  "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
                  "U", "V", "W", "X", "Y", "Z", "SPACE", "NOTHING"]
