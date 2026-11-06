import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Academic enrollment only: possession of a QR is not proof of official validity.
@MainActor @Observable final class TestPassStore {
    var linked = false
    var displayID: String?
    private func updateDisplayID(_ data: [String: Any]?) {
        // Local alias only; never changes the official pass number or stored schema.
        displayID = (data?["fingerprint"] as? String).map { "XP-" + $0.prefix(16).uppercased() }
    }
    var busy = false
    var loaded = false
    var message: String?
    private var revision = UUID()
    private var ownerID: String?
    func reset() {
        revision = UUID(); ownerID = nil; linked = false; displayID = nil; busy = false; loaded = false; message = nil
    }
    func load() async {
        guard !busy, let user = Auth.auth().currentUser, user.isEmailVerified else { return }
        if ownerID != user.uid { reset(); ownerID = user.uid }
        let token = revision
        busy = true
        defer { if token == revision { busy = false } }
        do {
            _ = try await user.getIDToken(forcingRefresh: true)
            let result = try await Firestore.firestore().collection("profiles").document(user.uid)
                .collection("testPasses").document("current").getDocument(source: .server)
            guard token == revision, Auth.auth().currentUser?.uid == user.uid else { return }
            linked = result.exists; updateDisplayID(result.data()); loaded = true; message = nil
        } catch {
            guard token == revision else { return }
            loaded = false; message = "No se pudo consultar el pase. Revisa la conexión y las reglas de Firestore."
        }
    }
    func change(fingerprint: String?) async {
        guard !busy, loaded, let user = Auth.auth().currentUser,
              user.isEmailVerified, user.uid == ownerID else { return }
        let token = revision
        busy = true; message = nil
        defer { if token == revision { busy = false } }
        let db = Firestore.firestore()
        let own = db.collection("profiles").document(user.uid).collection("testPasses").document("current")
        do {
            _ = try await user.getIDToken(forcingRefresh: true)
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let previous = try transaction.getDocument(own)
                    if let fingerprint {
                        if previous.exists {
                            guard previous.data()?["fingerprint"] as? String == fingerprint else {
                                throw NSError(domain: "TestPass", code: 1)
                            }
                            return nil
                        }
                        let claim = db.collection("testPassClaims").document(fingerprint)
                        guard try !transaction.getDocument(claim).exists else { throw NSError(domain: "TestPass", code: 2) }
                        transaction.setData(["fingerprint": fingerprint, "label": "XP-PRUEBA-001",
                            "createdAt": FieldValue.serverTimestamp()], forDocument: own)
                        transaction.setData(["linked": true], forDocument: claim)
                    } else if let old = previous.data()?["fingerprint"] as? String {
                        transaction.deleteDocument(db.collection("testPassClaims").document(old))
                        transaction.deleteDocument(own)
                    }
                    return nil
                } catch { errorPointer?.pointee = error as NSError; return nil }
            }
            let result = try await own.getDocument(source: .server)
            guard token == revision, Auth.auth().currentUser?.uid == user.uid else { return }
            linked = result.exists
            updateDisplayID(result.data())
            message = linked ? "XoloPass vinculado en la nube. Uso académico; sin validez para el estadio." : "Pase desvinculado de la cuenta."
        } catch {
            guard token == revision else { return }
            message = "No se pudo confirmar el cambio. El QR puede estar vinculado a otra cuenta, ya tienes otro pase o falta conexión/permisos. Reintenta la consulta."
        }
    }
}
