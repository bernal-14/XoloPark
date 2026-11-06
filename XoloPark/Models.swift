import SwiftUI
import Observation
import FirebaseAuth
import FirebaseFirestore

enum Route: Hashable { case match, parking, payment, confirmation, access, account, scanner, email, password }
enum Theme {
    // Read the asset in an explicit sRGB context. A desktop device-RGB
    // sample interpreted as sRGB can visibly change the original red.
    static let red: Color = {
        guard let image = UIImage(named: "header-xolo")?.cgImage,
              let sample = image.cropping(to: CGRect(x: image.width - 5, y: 5, width: 1, height: 1)),
              let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            return Color(.sRGB, red: 237 / 255, green: 20 / 255, blue: 35 / 255, opacity: 1)
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        let rendered = pixel.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return false }
            context.draw(sample, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        guard rendered, pixel[3] == 255 else { return Color.red }
        return Color(.sRGB, red: Double(pixel[0]) / 255,
                     green: Double(pixel[1]) / 255, blue: Double(pixel[2]) / 255, opacity: 1)
    }()
    static let cream = Color(red: 0.969, green: 0.961, blue: 0.941)
    static let gold = Color(red: 0.60, green: 0.51, blue: 0.29)
    static let ink = Color(red: 0.14, green: 0.15, blue: 0.17)
}
struct Space: Identifiable, Equatable {
    let id: String
    let zone: String
    let occupied: Bool
    var price: Int { id.hasPrefix("P") ? 250 : 150 }
}
struct Reservation { let space: Space; let method: String; let folio: String }
@MainActor @Observable final class DemoStore {
    static let eventID = "xolos-atlas-demo-2026"
    var cloudReady = false
    var loading = false
    var saving = false
    var cloudMessage: String?
    var reservedIDs: Set<String> = []
    private var generation = UUID()
    func unavailable(_ space: Space) -> Bool { space.occupied || reservedIDs.contains(space.id) }
    var pass: String?
    var selected: Space?
    var reservation: Reservation?
    static let spaces: [Space] = [
        .init(id: "D-01", zone: "Accesible", occupied: false),
        .init(id: "D-02", zone: "Accesible", occupied: true),
        .init(id: "P-01", zone: "Palco / Platea", occupied: true),
        .init(id: "P-02", zone: "Palco / Platea", occupied: false),
        .init(id: "A-01", zone: "General", occupied: true),
        .init(id: "A-02", zone: "General", occupied: false),
        .init(id: "A-03", zone: "General", occupied: false),
        .init(id: "A-04", zone: "General", occupied: false)
    ]
    private func decode(_ data: [String: Any]) throws -> Reservation {
        guard let id = data["spaceID"] as? String,
              let space = Self.spaces.first(where: { $0.id == id }),
              let method = data["method"] as? String,
              let folio = data["folio"] as? String else {
            throw NSError(domain: "XoloPark", code: 1, userInfo: [NSLocalizedDescriptionKey: "La reservación tiene un formato no compatible."])
        }
        return Reservation(space: space, method: method, folio: folio)
    }
    func refreshReservations() async {
        guard !loading, let user = Auth.auth().currentUser, user.isEmailVerified else { return }
        let current = generation
        loading = true; cloudReady = false; cloudMessage = nil
        defer { if generation == current { loading = false } }
        do {
            _ = try await user.getIDToken(forcingRefresh: true)
            let db = Firestore.firestore()
            let own = try await db.collection("profiles").document(user.uid)
                .collection("reservations").document(Self.eventID).getDocument(source: .server)
            let locks = try await db.collection("demoEvents").document(Self.eventID)
                .collection("locks").getDocuments(source: .server)
            try Task.checkCancellation()
            guard generation == current, Auth.auth().currentUser?.uid == user.uid else { return }
            reservation = try own.data().map { try decode($0) }
            reservedIDs = Set(locks.documents.map(\.documentID))
            if let selected, unavailable(selected) { self.selected = nil }
            cloudReady = true
        } catch {
            guard generation == current else { return }
            cloudMessage = "No se pudo consultar la nube. Revisa tu conexión y los permisos de Firestore. No se confirmarán reservaciones sin conexión."
        }
    }
    func reserve(_ method: String) async -> Bool {
        guard !saving, cloudReady, let selected, !unavailable(selected),
              let user = Auth.auth().currentUser, user.isEmailVerified else { return false }
        let current = generation
        saving = true; cloudMessage = nil
        defer { if generation == current { saving = false } }
        let db = Firestore.firestore()
        let own = db.collection("profiles").document(user.uid).collection("reservations").document(Self.eventID)
        let lock = db.collection("demoEvents").document(Self.eventID).collection("locks").document(selected.id)
        let folio = "XP-DEMO-" + UUID().uuidString
        do {
            _ = try await user.getIDToken(forcingRefresh: true)
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    // One immutable reservation per account/event; retries are idempotent.
                    let existing = try transaction.getDocument(own)
                    if existing.exists { return nil }
                    let occupied = try transaction.getDocument(lock)
                    guard !occupied.exists else {
                        throw NSError(domain: "XoloPark", code: 2, userInfo: [NSLocalizedDescriptionKey: "Otro usuario ya reservó este cajón."])
                    }
                    transaction.setData(["spaceID": selected.id, "method": method,
                        "folio": folio, "createdAt": FieldValue.serverTimestamp(),
                        "paymentStatus": "simulated"], forDocument: own)
                    transaction.setData(["reserved": true], forDocument: lock)
                    return nil
                } catch { errorPointer?.pointee = error as NSError; return nil }
            }
            let result = try await own.getDocument(source: .server)
            guard generation == current, Auth.auth().currentUser?.uid == user.uid else { return false }
            reservation = try decode(result.data() ?? [:])
            reservedIDs.insert(reservation!.space.id)
            return true
        } catch {
            guard generation == current else { return false }
            cloudMessage = "No se pudo confirmar la reservación. El cajón puede estar ocupado o faltar conexión/permisos. Actualiza la disponibilidad antes de reintentar."
            cloudReady = false
            return false
        }
    }
    func signOut() {
        generation = UUID(); cloudReady = false; loading = false; saving = false
        reservedIDs = []; cloudMessage = nil
        selected = nil; reservation = nil; pass = nil
    }
    static func validEmail(_ value: String) -> Bool {
        value.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
