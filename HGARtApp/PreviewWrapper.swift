//
//  PreviewWrapper.swift
//  HGArt
//
//  Created by  Stanislav Grinshpun on 2025-09-01.
//

#if DEBUG
//import SwiftUI
//
//struct ViewControllerPreview: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> UIViewController {
//        return ViewController()
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
//
//    typealias UIViewControllerType = UIViewController
//}
//
//
//#Preview {    
//    ViewControllerPreview()
//}

import SwiftUI

struct PreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return CameraPermissionDeniedViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

#Preview {
    PreviewWrapper()
}
#endif
