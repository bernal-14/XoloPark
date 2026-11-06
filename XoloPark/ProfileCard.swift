import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileCard: View {
    @Environment(AuthSession.self) private var auth
    @State private var name = ""
    @State private var savedName = ""
    @State private var loading = false
    @State private var saving = false
    @State private var loaded = false
    @State private var notice: String?
    private var cleanedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var body: some View {
        Card {
            Text("Mi perfil").font(.headline)
            TextField("Nombre o apodo", text: $name).textContentType(.nickname).fieldStyle()
                .disabled(loading || saving || !loaded)
            Text("Al guardar, tu nombre o apodo se enviará a Firebase y quedará asociado a tu cuenta. No necesitas escribir tu nombre completo.")
                .font(.caption).foregroundStyle(.secondary)
            if loading || saving { ProgressView(loading ? "Cargando perfil…" : "Guardando en la nube…") }
            if let notice { Text(notice).font(.caption).accessibilityLabel(notice) }
            if loaded {
                ActionButton(title: "Guardar perfil", disabled: saving || loading || cleanedName.isEmpty || cleanedName.count > 80 || cleanedName == savedName) {
                    Task { await save() }
                }
                if cleanedName.count > 80 { Text("Máximo 80 caracteres.").font(.caption).foregroundStyle(.red) }
            } else if !loading {
                Button("Reintentar carga") { Task { await load() } }
            }
        }.task(id: auth.uid) { await load() }
    }
    private func load() async {
        name = ""; savedName = ""; loaded = false; notice = nil
        guard let user = Auth.auth().currentUser, user.uid == auth.uid else { return }
        let uid = user.uid
        loading = true
        defer { loading = false }
        do {
            // Refresh the token so Firestore receives the verified-email claim.
            _ = try await user.getIDToken(forcingRefresh: true)
            try Task.checkCancellation()
            guard Auth.auth().currentUser?.uid == uid else { return }
            let document = try await Firestore.firestore().collection("profiles").document(uid).getDocument(source: .server)
            try Task.checkCancellation()
            guard auth.uid == uid else { return }
            if document.exists {
                guard let stored = document.data()?["displayName"] as? String else {
                    notice = "El perfil tiene un formato no compatible. No se modificó."; return
                }
                name = stored; savedName = stored
            } else {
                notice = "Todavía no tienes un perfil guardado."
            }
            loaded = true
        } catch is CancellationError {
        } catch {
            guard auth.uid == uid else { return }
            notice = "No se pudo cargar el perfil. Revisa tu conexión y que tu correo esté verificado; después reintenta."
        }
    }
    private func save() async {
        guard !saving, loaded, !cleanedName.isEmpty, cleanedName.count <= 80,
              let user = Auth.auth().currentUser, user.uid == auth.uid else { return }
        let uid = user.uid
        let submitted = cleanedName
        saving = true; notice = nil
        defer { saving = false }
        do {
            _ = try await user.getIDToken(forcingRefresh: true)
            guard Auth.auth().currentUser?.uid == uid else { return }
            let db = Firestore.firestore()
            let ref = db.collection("profiles").document(uid)
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let existing = try transaction.getDocument(ref)
                    var data: [String: Any] = [
                        "displayName": submitted,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                    if existing.exists {
                        transaction.updateData(data, forDocument: ref)
                    } else {
                        data["createdAt"] = FieldValue.serverTimestamp()
                        transaction.setData(data, forDocument: ref)
                    }
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            guard auth.uid == uid else { return }
            name = submitted; savedName = submitted
            notice = "Perfil guardado en la nube."
        } catch {
            guard auth.uid == uid else { return }
            notice = "No se pudo confirmar el guardado. Revisa la conexión e inténtalo de nuevo. No se mostrará como guardado hasta recibir confirmación."
        }
    }
}
