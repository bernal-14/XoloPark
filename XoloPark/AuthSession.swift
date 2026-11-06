import SwiftUI
import FirebaseAuth

@MainActor @Observable final class AuthSession {
    private(set) var user: User?
    private(set) var ready = false
    private(set) var busy = false
    var message: String?
    @ObservationIgnored private var listener: AuthStateDidChangeListenerHandle?
    var uid: String? { user?.uid }
    var email: String { user?.email ?? "" }
    var verified: Bool { user?.isEmailVerified == true }

    func start() {
        guard listener == nil else { return }
        Auth.auth().languageCode = "es"
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user; self?.ready = true }
        }
    }
    func perform(_ operation: () async throws -> Void) async {
        guard !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        do { try await operation() }
        catch { message = Self.explain(error) }
    }
    func login(email: String, password: String) async {
        await perform {
            let result = try await Auth.auth().signIn(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            user = result.user
        }
    }
    func register(email: String, password: String) async {
        await perform {
            let result = try await Auth.auth().createUser(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            user = result.user
            do {
                try await result.user.sendEmailVerification()
                message = "Cuenta creada. Revisa tu correo para verificarla."
            } catch {
                message = "Tu cuenta se creó, pero no pudimos enviar la verificación. Usa Reenviar verificación; no necesitas registrarte otra vez."
            }
        }
    }
    func reset(email: String) async {
        await perform {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                if (error as NSError).code != AuthErrorCode.userNotFound.rawValue { throw error }
            }
            message = "Si el correo corresponde a una cuenta, recibirás instrucciones para recuperar tu contraseña. Revisa también spam."
        }
    }
    func resend() async {
        await perform {
            guard let user else { return }
            try await user.sendEmailVerification()
            message = "Correo de verificación enviado. Revisa también spam."
        }
    }
    func refresh() async {
        await perform {
            guard let user else { return }
            try await user.reload()
            self.user = Auth.auth().currentUser
            if self.user?.isEmailVerified != true { message = "El correo todavía no aparece verificado. Abre el enlace recibido y vuelve a comprobar." }
        }
    }
    func logout() {
        guard !busy else { return }
        do { try Auth.auth().signOut(); user = nil; message = nil }
        catch { message = Self.explain(error) }
    }
    func changePassword(current: String, next: String) async {
        await perform {
            guard let user, let email = user.email else { return }
            let credential = EmailAuthProvider.credential(withEmail: email, password: current)
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: next)
            message = "Contraseña actualizada."
        }
    }
    func changeEmail(newEmail: String, password: String) async {
        await perform {
            guard let user, let email = user.email else { return }
            try await user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, password: password))
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail.trimmingCharacters(in: .whitespacesAndNewlines))
            message = "Enviamos un enlace al nuevo correo. El cambio solo se aplicará cuando lo verifiques. Después, vuelve a iniciar sesión."
        }
    }
    static func explain(_ error: Error) -> String {
        switch (error as NSError).code {
        case AuthErrorCode.networkError.rawValue: return "No pudimos conectar. Revisa tu conexión e inténtalo de nuevo."
        case AuthErrorCode.tooManyRequests.rawValue: return "Hay demasiados intentos. Espera unos minutos antes de volver a intentarlo."
        case AuthErrorCode.invalidEmail.rawValue: return "Escribe un correo electrónico válido."
        case AuthErrorCode.weakPassword.rawValue: return "La contraseña no cumple los requisitos de seguridad."
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "No se pudo crear la cuenta con ese correo. Intenta iniciar sesión o recuperar el acceso."
        case AuthErrorCode.operationNotAllowed.rawValue: return "Este método de acceso aún no está habilitado en Firebase."
        case AuthErrorCode.requiresRecentLogin.rawValue: return "Por seguridad, cierra sesión y vuelve a entrar antes de hacer este cambio."
        case AuthErrorCode.userDisabled.rawValue, AuthErrorCode.userTokenExpired.rawValue, AuthErrorCode.invalidUserToken.rawValue:
            return "La sesión no es válida. Cierra sesión y vuelve a iniciar sesión."
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.userNotFound.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return "No pudimos verificar tus credenciales. Revisa el correo y la contraseña."
        default: return "No se pudo completar la operación. Inténtalo de nuevo."
        }
    }
}

struct VerifyEmailView: View {
    @Environment(AuthSession.self) private var auth
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "envelope.badge.shield.half.filled").font(.system(size: 54)).foregroundStyle(Theme.red)
            Text("Verifica tu correo").font(.title.bold())
            Text(auth.email).textSelection(.enabled)
            Text("Abre el enlace de verificación que recibiste antes de entrar a XoloPark.").multilineTextAlignment(.center)
            ActionButton(title: "Ya verifiqué mi correo", disabled: auth.busy) { Task { await auth.refresh() } }
            Button("Reenviar verificación") { Task { await auth.resend() } }.disabled(auth.busy)
            Button("Cerrar sesión") { auth.logout() }.disabled(auth.busy)
            if auth.busy { ProgressView() }
        }.padding(30).frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.cream)
    }
}

