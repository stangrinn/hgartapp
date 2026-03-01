//
//  PreviewWrapper.swift
//  HGArt
//
//  Created by  Stanislav Grinshpun on 2025-09-01.
//

#if DEBUG

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
