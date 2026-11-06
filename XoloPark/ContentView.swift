import SwiftUI

struct ContentView: View {
    @State private var store = DemoStore()
    @State private var testPass = TestPassStore()
    @State private var auth = AuthSession()
    @State private var path: [Route] = []
    @State private var menu = false
    var body: some View {
        Group {
            if !auth.ready {
                ProgressView("Cargando sesión…")
            } else if auth.user != nil && !auth.verified {
                VerifyEmailView()
            } else if auth.user != nil {
                NavigationStack(path: $path) {
                    page(nil).navigationDestination(for: Route.self) { page($0) }
                }
                .task(id: auth.uid) { await store.refreshReservations() }
                .overlay(alignment: .trailing) {
                    if menu {
                        ZStack(alignment: .trailing) {
                            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { menu = false }
                            VStack(alignment: .leading, spacing: 24) {
                                HStack {
                                    Text("XOLOPARK").font(.title2.bold()); Spacer()
                                    Button { menu = false } label: { Image(systemName: "xmark") }
                                        .accessibilityLabel("Cerrar menú")
                                }
                                Divider()
                                item("Inicio", "house", nil)
                                item("Mi cuenta", "person.crop.circle", .account)
                                item("XoloPass", "qrcode", .account)
                                item("Mi acceso", "ticket", .access)
                                Spacer()
                                Button("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right") {
                                    auth.logout()
                                }
                                Text("Prototipo académico").font(.caption)
                            }.padding(28).frame(width: 290).frame(maxHeight: .infinity)
                                .background(Theme.red).foregroundStyle(.white)
                        }.transition(.move(edge: .trailing))
                    }
                }
            } else { LoginView() }
        }.environment(store).environment(auth).environment(testPass).tint(Theme.red).preferredColorScheme(.light)
            .task { auth.start() }
            .onChange(of: auth.uid) { _, _ in
                menu = false; path = []; store.signOut(); testPass.reset()
            }
            .alert("XoloPark", isPresented: Binding(get: { auth.message != nil }, set: { if !$0 { auth.message = nil } })) {
                Button("Entendido") { auth.message = nil }
            } message: { Text(auth.message ?? "") }
    }
    private func item(_ title: String, _ icon: String, _ route: Route?) -> some View {
        Button(title, systemImage: icon) { path = route.map { [$0] } ?? []; menu = false }
            .font(.headline).frame(minHeight: 44)
    }
    private func go(_ route: Route) {
        if route == .access { path = [.access] } else { path.append(route) }
    }
    private func page(_ route: Route?) -> some View {
        VStack(spacing: 0) {
            BrandHeader(title: title(route), back: path.isEmpty ? nil : { path.removeLast() }) {
                withAnimation(.easeInOut(duration: 0.2)) { menu = true }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch route {
                    case nil: HomeView(go: go)
                    case .match: MatchView(go: go)
                    case .parking: ParkingView(go: go)
                    case .payment: PaymentView(go: go)
                    case .confirmation: ConfirmationView(go: go)
                    case .access: AccessView()
                    case .account: AccountView(go: go)
                    case .scanner: ScannerView()
                    case .email: EmailView()
                    case .password: PasswordView()
                    }
                    DemoFooter()
                }.padding(24)
            }.background(Theme.cream)
        }.toolbar(.hidden, for: .navigationBar)
            .background(Theme.red.ignoresSafeArea(edges: .top))
    }
    private func title(_ route: Route?) -> String {
        switch route {
        case nil: return "INICIO"
        case .match: return "PARTIDO"
        case .parking: return "ELIGE TU CAJÓN"
        case .payment: return "PAGO"
        case .confirmation: return "¡TODO LISTO!"
        case .access: return "MI ACCESO"
        case .account: return "MI PERFIL"
        case .scanner: return "VINCULAR XOLOPASS"
        case .email: return "CAMBIAR CORREO"
        case .password: return "CONTRASEÑA"
        }
    }
}
