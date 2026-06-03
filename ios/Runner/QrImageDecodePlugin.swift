import Flutter
import UIKit
import Vision

/// Gallery QR decode using Apple Vision (`VNDetectBarcodesRequest`) — no extra pods.
final class QrImageDecodePlugin: NSObject, FlutterPlugin {
  private static let channelName = "com.example.flutter_auth_qrcode_2fa/qr_decode"
  private static let methodDecodeFromImagePath = "decodeFromImagePath"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = QrImageDecodePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Self.methodDecodeFromImagePath:
      decodeFromImagePath(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func decodeFromImagePath(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          !path.isEmpty
    else {
      result(
        FlutterError(
          code: "INVALID_PATH",
          message: "無法讀取圖片：路徑為空",
          details: nil
        )
      )
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      guard let image = self.loadImage(path: path) else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "INVALID_PATH",
              message: "無法讀取圖片",
              details: nil
            )
          )
        }
        return
      }

      let payload = self.detectQrPayload(in: image)
      DispatchQueue.main.async {
        guard let payload, !payload.isEmpty else {
          result(
            FlutterError(
              code: "NOT_FOUND",
              message: "無法從圖片中辨識 QR 碼",
              details: nil
            )
          )
          return
        }
        result([
          "success": true,
          "payload": payload,
        ])
      }
    }
  }

  private func loadImage(path: String) -> UIImage? {
    if path.hasPrefix("file://"), let url = URL(string: path) {
      return UIImage(contentsOfFile: url.path)
    }
    if FileManager.default.fileExists(atPath: path) {
      return UIImage(contentsOfFile: path)
    }
    return nil
  }

  private func detectQrPayload(in image: UIImage) -> String? {
    guard let cgImage = image.cgImage else {
      return nil
    }

    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return nil
    }

    let observations = request.results as? [VNBarcodeObservation] ?? []
    for observation in observations {
      guard observation.symbology == .qr,
            let payload = observation.payloadStringValue?
              .trimmingCharacters(in: .whitespacesAndNewlines),
            !payload.isEmpty
      else { continue }
      return payload
    }
    return nil
  }
}
