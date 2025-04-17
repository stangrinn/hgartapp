import UIKit
import ReplayKit

class RecordingManager {
    private let recorder = RPScreenRecorder.shared()
    private var isRecording = false
    
    var isRecordingActive: Bool {
        return isRecording
    }
    
    func startRecording(completion: @escaping (Error?) -> Void) {
        recorder.startRecording { [weak self] error in
            if let error = error {
                print("Start recording error: \(error.localizedDescription)")
                completion(error)
            } else {
                self?.isRecording = true
                print("Recording started")
                completion(nil)
            }
        }
    }
    
    func stopRecording(completion: @escaping (RPPreviewViewController?, Error?) -> Void) {
        recorder.stopRecording { [weak self] previewVC, error in
            self?.isRecording = false
            if let error = error {
                print("Stop recording error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            completion(previewVC, nil)
        }
    }
} 
