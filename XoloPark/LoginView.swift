import SwiftUI

struct LoginView: View {
    @Environment(AuthSession.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var mode = Mode.login
    @State private var attempted = false
    @FocusState private var focused: Field?
    private enum Field: Hashable { case email, password, confirmation }
    private enum Mode { case login, register, reset }
    private var emailValid: Bool {
        DemoStore.validEmail(email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    private var validationMessage: String? {
        if !emailValid { return "Escribe un correo completo, por ejemplo nombre@dominio.com, sin espacios dentro de la dirección." }
        if mode == .reset { return nil }
        if password.isEmpty { return "El campo Contraseña está vacío. Vuelve a seleccionarlo si usaste Autorrelleno." }
        if mode == .register {
            if password.count < 12 { return "La contraseña debe tener al menos 12 caracteres." }
            if confirmation.isEmpty { return "Completa Confirma tu contraseña con la misma contraseña." }
            if password != confirmation { return "Las contraseñas no coinciden exactamente. Revisa ambos campos; no se eliminan espacios de las contraseñas." }
        }
        return nil
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Image("login-background").resizable().scaledToFill().frame(height: 210).clipped()
                    Text("XOLOPARK").font(.system(size: 44, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                }
                Image("xolo-badge").resizable().scaledToFit().frame(width: 90, height: 90).offset(y: -28).padding(.bottom, -8)
                VStack(spacing: 16) {
                    Text(mode == .login ? "Bienvenido" : mode == .register ? "Crea tu cuenta" : "Recupera tu acceso").font(.title2.bold())
                    TextField("Correo electrónico", text: $email).textContentType(.emailAddress)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never).fieldStyle()
                        .focused($focused, equals: .email)
                    if mode != .reset {
                        SecureField("Contraseña", text: $password)
                            .textContentType(mode == .register ? .newPassword : .password).fieldStyle()
                            .focused($focused, equals: .password)
                    }
                    if mode == .register {
                        SecureField("Confirma tu contraseña", text: $confirmation).textContentType(.newPassword).fieldStyle()
                            .focused($focused, equals: .confirmation)
                        VStack(alignment: .leading, spacing: 8) {
                            requirement("Correo con formato válido", met: emailValid)
                            requirement("Contraseña de 12 caracteres o más", met: password.count >= 12)
                            requirement("Ambas contraseñas coinciden", met: !password.isEmpty && password == confirmation)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Text("Usa al menos 12 caracteres. Al registrarte se creará una cuenta en Firebase y se enviará un correo de verificación.").font(.caption).foregroundStyle(.secondary)
                    }
                    if mode == .reset {
                        Text("Te enviaremos un enlace para restablecer tu contraseña.").font(.caption)
                    }
                    if attempted, let validationMessage {
                        Text(validationMessage).font(.subheadline).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ActionButton(title: mode == .login ? "INICIAR SESIÓN" : mode == .register ? "CREAR CUENTA" : "ENVIAR ENLACE", disabled: auth.busy) {
                        focused = nil
                        attempted = true
                        guard validationMessage == nil else { return }
                        Task {
                            switch mode {
                            case .login: await auth.login(email: email, password: password)
                            case .register: await auth.register(email: email, password: password)
                            case .reset: await auth.reset(email: email)
                            }
                            password = ""; confirmation = ""
                        }
                    }
                    if auth.busy { ProgressView("Conectando…") }
                    if mode == .login {
                        Button("¿Olvidaste tu contraseña?") { switchMode(.reset) }.frame(minHeight: 44)
                        ActionButton(title: "REGÍSTRATE", color: Color(red: 0.3, green: 0.63, blue: 0.43), disabled: auth.busy) { switchMode(.register) }
                        ActionButton(title: "Apple · Pendiente de configurar", color: .black, disabled: true) {}
                        Text("La sesión permanece abierta en este dispositivo hasta que cierres sesión.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button("Volver a iniciar sesión") { switchMode(.login) }.frame(minHeight: 44)
                    }
                    Text("Cuentas reales · Reservaciones y pagos de demostración").font(.caption2).foregroundStyle(.secondary)
                    Text("Formulario de acceso · revisión 3").font(.caption2).foregroundStyle(.secondary)
                }.padding(.horizontal, 32).padding(.bottom, 24).disabled(auth.busy)
            }
        }.scrollDismissesKeyboard(.interactively).background(Theme.cream.ignoresSafeArea())
    }
    private func switchMode(_ next: Mode) {
        focused = nil; attempted = false
        mode = next; password = ""; confirmation = ""
    }
    private func requirement(_ title: String, met: Bool) -> some View {
        Label(title, systemImage: met ? "checkmark.circle.fill" : "circle")
            .font(.caption).foregroundStyle(met ? Color.green : Color.secondary)
    }
}
