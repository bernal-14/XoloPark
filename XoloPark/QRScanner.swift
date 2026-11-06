import SwiftUI
import AVFoundation
import VisionKit
import CryptoKit

/// Reads QR codes locally. A read is NOT proof of ownership or a valid pass.
struct LiveQRScanner: UIViewControllerRepresentable {
    let onRead: (String) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onRead: onRead, onError: onError) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }
    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        guard !scanner.isScanning, !context.coordinator.finished else { return }
        do { try scanner.startScanning() }
        catch {
            let coordinator = context.coordinator
            DispatchQueue.main.async { coordinator.fail() }
        }
    }
    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        coordinator.finished = true
        scanner.stopScanning()
    }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var finished = false
        let onRead: (String) -> Void
        let onError: (String) -> Void
        init(onRead: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onRead = onRead
            self.onError = onError
        }
        func fail() {
            guard !finished else { return }
            finished = true
            onError("No se pudo iniciar la cámara. Cierra otras apps que la estén usando y vuelve a intentarlo.")
        }
        func dataScanner(_ scanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !finished else { return }
            for item in addedItems {
                if case .barcode(let code) = item, let value = code.payloadStringValue, !value.isEmpty {
                    // Do not log, persist, open URLs, or claim a pass from unverified QR content.
                    finished = true
                    scanner.stopScanning()
                    let digest = SHA256.hash(data: Data(("XoloPark-test-pass-v1:" + value).utf8))
                    onRead(digest.map { String(format: "%02x", $0) }.joined())
                    return
                }
            }
        }
        func dataScanner(_ scanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            scanner.stopScanning()
            fail()
        }
    }
}

struct ScannerView: View {
    @Environment(TestPassStore.self) private var pass
    @State private var fingerprint: String?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var ready = false
    @State private var recognized = false
    @State private var message = "Preparando cámara…"
    @State private var denied = false
    @State private var scannerID = UUID()

    var body: some View {
        Text("Escanea el QR de tu pase").font(.title2.bold())
        Text("Apunta la cámara al código QR.").foregroundStyle(.secondary)
        Group {
            if ready && !recognized && scenePhase == .active {
                LiveQRScanner(onRead: {
                    fingerprint = $0
                    recognized = true
                    ready = false
                }, onError: {
                    message = $0
                    ready = false
                }).id(scannerID)
            } else {
                VStack(spacing: 18) {
                    Image(systemName: recognized ? "qrcode" : "camera").font(.system(size: 60))
                    Text(recognized ? "QR leído correctamente" : message).multilineTextAlignment(.center)
                }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.white).background(Theme.ink)
            }
        }.frame(height: 340).clipShape(RoundedRectangle(cornerRadius: 20))
        if recognized {
            Text("QR leído. Vincula tu XoloPass para usarlo con tu reservación de XoloPark. No comprueba vigencia oficial para el estadio.")
                .font(.subheadline)
            if !pass.linked {
                ActionButton(title: pass.busy ? "Guardando…" : "Vincular XoloPass", disabled: pass.busy || !pass.loaded || fingerprint == nil) {
                    Task { await pass.change(fingerprint: fingerprint); if pass.linked { fingerprint = nil } }
                }
            }
            if let notice = pass.message { Text(notice).font(.caption) }
            ActionButton(title: "Escanear otro QR") {
                fingerprint = nil
                recognized = false
                scannerID = UUID()
                Task { await prepare() }
            }
        } else if denied {
            ActionButton(title: "Abrir ajustes de cámara") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } else if !ready {
            Button("Reintentar") { Task { await prepare() } }.frame(minHeight: 44)
        }
        Text("Solo al confirmar se enviará una huella SHA-256 del QR a Firebase vinculada a tu cuenta. No se enviará el contenido original ni se abrirán enlaces. Vincula únicamente un pase que te pertenezca.")
            .font(.caption).foregroundStyle(.secondary)
            .task { await pass.load(); await prepare() }
            .onDisappear { fingerprint = nil }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && !recognized { Task { await prepare() } }
                else if phase != .active { ready = false }
            }
    }
    @MainActor private func prepare() async {
        guard !recognized else { return }
        ready = false
        denied = false
        guard DataScannerViewController.isSupported else {
            message = "El escáner requiere un iPhone compatible con cámara. No está disponible en el simulador."
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let allowed = status == .notDetermined
            ? await AVCaptureDevice.requestAccess(for: .video)
            : status == .authorized
        guard allowed else {
            denied = true
            message = "Permite el acceso a la cámara en Ajustes para escanear."
            return
        }
        guard DataScannerViewController.isAvailable else {
            message = "La cámara no está disponible. Revisa las restricciones del dispositivo e inténtalo de nuevo."
            return
        }
        ready = scenePhase == .active
    }
}
