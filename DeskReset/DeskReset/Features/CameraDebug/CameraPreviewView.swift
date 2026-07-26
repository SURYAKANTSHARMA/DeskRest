//
//  CameraPreviewView.swift
//  DeskReset
//
//  NSViewRepresentable that hosts an AVCaptureVideoPreviewLayer.
//  The preview layer renders the live camera feed directly — no frame
//  processing, no image saving.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: NSViewRepresentable {

    let session: AVCaptureSession

    func makeNSView(context: Context) -> CameraHostView {
        CameraHostView(session: session)
    }

    func updateNSView(_ nsView: CameraHostView, context: Context) {
        nsView.updateSession(session)
    }

    // MARK: — Host NSView

    final class CameraHostView: NSView {

        private let previewLayer: AVCaptureVideoPreviewLayer

        init(session: AVCaptureSession) {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            super.init(frame: .zero)
            wantsLayer      = true
            layer           = previewLayer
            previewLayer.videoGravity   = .resizeAspectFill
            previewLayer.backgroundColor = NSColor.black.cgColor
        }

        required init?(coder: NSCoder) { fatalError("Not implemented") }

        override func layout() {
            super.layout()
            // Disable implicit animations so the layer snaps to its new size.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = bounds
            CATransaction.commit()
        }

        func updateSession(_ session: AVCaptureSession) {
            guard previewLayer.session !== session else { return }
            previewLayer.session = session
        }
    }
}
