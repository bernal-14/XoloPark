import SwiftUI

struct AccountView: View {
    @Environment(TestPassStore.self) private var testPass
    @Environment(DemoStore.self) private var store
    @Environment(AuthSession.self) private var auth
    let go: (Route) -> Void
    @State private var unlink = false
    var body: some View {
        Card {
            Caption(text: "AFICIONADO XOLO")
            Text("Tu cuenta, siempre contigo").font(.headline)
        }
        Caption(text: "INFORMACIÓN Y SEGURIDAD")
        ProfileCard().id(auth.uid)
        Card {
            Text("Correo electrónico").font(.caption).foregroundStyle(.secondary)
            Text(auth.email).font(.subheadline)
            Button("Cambiar correo →") { go(.email) }.font(.subheadline.bold()).frame(minHeight: 44)
            Divider()
            Text("Contraseña   ••••••••")
            Button("Cambiar contraseña →") { go(.password) }.font(.subheadline.bold()).frame(minHeight: 44)
        }
        Caption(text: "MI XOLOPASS")
        VStack(alignment: .leading, spacing: 18) {
            Text("XOLOPASS").font(.title.bold())
            if testPass.linked {
                Label("XoloPass vinculado", systemImage: "checkmark.circle.fill").foregroundStyle(.mint).font(.caption)
                Text(testPass.displayID ?? "ID no disponible").font(.subheadline.bold().monospaced()).textSelection(.enabled)
                Text("ID interno de XoloPark · Uso académico\nSin validez para el estadio").font(.caption).foregroundStyle(.gray)
                ActionButton(title: "Desvincular XoloPass", disabled: testPass.busy) { unlink = true }
            } else {
                Text("Sin vincular").font(.caption).foregroundStyle(.gray)
                Text("Vincula tu pase escaneando su QR.").font(.subheadline)
                Text("Ten tu XoloPass a la mano.").font(.caption).foregroundStyle(.gray)
                ActionButton(title: "Escanear QR y vincular", disabled: testPass.busy || !testPass.loaded) { go(.scanner) }
            }
            if testPass.busy { ProgressView() }
            if let notice = testPass.message { Text(notice).font(.caption) }
            Button("Actualizar pase") { Task { await testPass.load() } }.disabled(testPass.busy)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(.white)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 18))
            .alert("¿Desvincular tu XoloPass?", isPresented: $unlink) {
                Button("Conservar", role: .cancel) {}
                Button("Desvincular", role: .destructive) { Task { await testPass.change(fingerprint: nil) } }
            } message: {
                Text("Se quitará el vínculo de tu cuenta en la nube. Podrás registrarlo de nuevo. No modifica ni cancela un XoloPass oficial.")
            }
            .task(id: auth.uid) { await testPass.load() }
    }
}
struct EmailView: View {
    @Environment(AuthSession.self) private var auth
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        Card {
            Text("Correo actual").font(.caption).foregroundStyle(.secondary)
            Text(auth.email)
            TextField("Nuevo correo", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress).fieldStyle()
            SecureField("Contraseña actual", text: $password).textContentType(.password).fieldStyle()
            Text("Enviaremos una verificación al nuevo correo. Tu dirección actual no cambia hasta que abras el enlace.").font(.caption)
        }
        ActionButton(title: "Verificar nuevo correo", disabled: auth.busy || password.isEmpty || !DemoStore.validEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) || email == auth.email) {
            Task { await auth.changeEmail(newEmail: email, password: password); password = "" }
        }
        if auth.busy { ProgressView() }
    }
}
struct PasswordView: View {
    @Environment(AuthSession.self) private var auth
    @State private var current = ""
    @State private var next = ""
    @State private var confirmation = ""
    var body: some View {
        Card {
            SecureField("Contraseña actual", text: $current).textContentType(.password).fieldStyle()
            SecureField("Nueva contraseña", text: $next).textContentType(.newPassword).fieldStyle()
            SecureField("Confirmar nueva contraseña", text: $confirmation).textContentType(.newPassword).fieldStyle()
            Text("Usa al menos 12 caracteres.").font(.caption).foregroundStyle(Theme.red)
            if !confirmation.isEmpty && next != confirmation {
                Text("Las contraseñas no coinciden.").font(.caption).foregroundStyle(Theme.red)
            }
        }
        ActionButton(title: "Actualizar contraseña", disabled: auth.busy || current.isEmpty || next.count < 12 || next != confirmation) {
            Task {
                await auth.changePassword(current: current, next: next)
                current = ""; next = ""; confirmation = ""
            }
        }
        if auth.busy { ProgressView() }
    }
}
