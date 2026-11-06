import SwiftUI
import CoreImage.CIFilterBuiltins

/// Versioned identifier, not a signed authorization token. Contains no user ID or original pass QR.
enum AccessQR {
    static func displayID(folio: String) -> String {
        folio.hasPrefix("XP-DEMO-") ? "XP-" + String(folio.dropFirst(8)) : folio
    }
    static func payload(folio: String) -> String {
        folio.hasPrefix("XP-DEMO-")
            ? "xolopark:reservation:v2:" + displayID(folio: folio)
            : "xolopark:reservation:v1:" + folio
    }
    static func image(folio: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload(folio: folio).utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }
}

struct ReservationQRCode: View {
    let folio: String
    var body: some View {
        if let code = AccessQR.image(folio: folio) {
            // Integral module scaling and a white quiet zone preserve scan reliability.
            let scale = max(1, 224 / code.width)
            Image(decorative: code, scale: 1)
                .interpolation(.none).resizable()
                .frame(width: CGFloat(code.width * scale), height: CGFloat(code.height * scale))
                .padding(CGFloat(4 * scale)).background(.white)
                .accessibilityLabel("Código QR de la reservación de XoloPark")
        } else {
            Label("No se pudo generar el QR. Conserva tu folio.", systemImage: "exclamationmark.triangle")
                .font(.caption)
        }
    }
}
