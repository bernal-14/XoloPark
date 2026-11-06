import SwiftUI

struct ParkingView: View {
    @Environment(DemoStore.self) private var store
    let go: (Route) -> Void
    var body: some View {
        Caption(text: "01 CAJÓN  —  02 PAGO  —  03 ACCESO")
        ReservationCloudStatus()
        Card {
            Text("XOLOS vs ATLAS").font(.headline)
            Text("25 SEP 2026 · Estadio Caliente").font(.caption).foregroundStyle(.secondary)
        }
        Text("Tu lugar, antes de llegar.").font(.title2.bold())
        Text("Toca un cajón disponible para seleccionarlo.").font(.subheadline).foregroundStyle(.secondary)
        Text("ACCESO AL ESTADIO").font(.caption.bold()).foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(12).background(Theme.ink, in: RoundedRectangle(cornerRadius: 8))
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 24) {
            ForEach(DemoStore.spaces) { space in
                Button { store.selected = space } label: {
                    VStack(spacing: 12) {
                        Text(space.id).font(.subheadline.bold())
                        Image(systemName: store.unavailable(space) ? "xmark" : store.selected == space ? "checkmark" : "parkingsign")
                        Text(space.zone == "General" ? "General" : space.id.hasPrefix("D") ? "Accesible" : "Palco").font(.system(size: 8))
                    }.frame(maxWidth: .infinity).frame(height: 98)
                        .foregroundStyle(store.selected == space ? .white : Theme.ink)
                        .background(store.selected == space ? Theme.red : store.unavailable(space) ? Color.gray.opacity(0.25) : .white,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.25)))
                }.disabled(!store.cloudReady || store.unavailable(space) || store.reservation != nil)
                    .accessibilityLabel("\(space.id), \(space.zone), \(store.unavailable(space) ? "ocupado" : store.selected == space ? "seleccionado" : "disponible")")
            }
        }
        Text("□ Libre    × Ocupado    ✓ Tu selección").font(.caption)
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.selected.map { "\($0.zone) · \($0.id)" } ?? "Selecciona tu lugar").font(.headline)
                    Text("1 vehículo · Precio de ejemplo").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let space = store.selected { Text("$\(space.price)").font(.title2.bold()) }
            }
        }
        if store.reservation != nil {
            Text("Ya tienes una reservación para este evento.")
            ActionButton(title: "Ver mi acceso") { go(.access) }
        } else {
            ActionButton(title: "Continuar al pago →", disabled: store.selected == nil || !store.cloudReady) { go(.payment) }
        }
        Text("Los cajones accesibles están destinados a personas que los necesitan.").font(.caption).foregroundStyle(.secondary)
    }
}
struct PaymentView: View {
    @Environment(DemoStore.self) private var store
    let go: (Route) -> Void
    @State private var method = "Tarjeta"
    var body: some View {
        Caption(text: "02 PAGO — TU LUGAR ESTÁ CASI LISTO")
        ReservationCloudStatus()
        if let space = store.selected {
            Card {
                Text("XOLOS vs ATLAS").font(.headline)
                Text("\(space.zone) · Cajón \(space.id) · 25 SEP 2026").font(.caption)
                HStack { Text("Total de ejemplo"); Spacer(); Text("$\(space.price) MXN").bold() }
            }
            Text("Elige cómo pagar").font(.title2.bold())
            Picker("Método de pago", selection: $method) {
                Text("Tarjeta").tag("Tarjeta"); Text("Apple Pay").tag("Apple Pay")
            }.pickerStyle(.segmented)
            if method == "Tarjeta" {
                Card {
                    Text("Tarjeta de demostración").font(.headline)
                    Label("TITULAR DE EJEMPLO", systemImage: "person")
                    Text("••••  ••••  ••••  4242").font(.title3.monospaced())
                    HStack { Text("MM / AA"); Spacer(); Text("CVV •••") }.foregroundStyle(.secondary)
                }
            } else {
                Card {
                    Label("Apple Pay", systemImage: "apple.logo").font(.title.bold())
                    Text("Vista ilustrativa. No se abrirá Wallet ni se realizará ningún cargo.").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Text("No ingreses datos bancarios reales.").font(.caption).foregroundStyle(Theme.red)
            ActionButton(title: store.saving ? "Confirmando en la nube…" : "Simular pago de $\(space.price) MXN →", color: method == "Apple Pay" ? .black : Theme.red, disabled: store.saving || !store.cloudReady) {
                Task { if await store.reserve(method) { go(.confirmation) } }
            }
        } else {
            Text("Primero selecciona un cajón.")
            ActionButton(title: "Elegir cajón") { go(.parking) }
        }
    }
}
struct ConfirmationView: View {
    @Environment(DemoStore.self) private var store
    let go: (Route) -> Void
    var body: some View {
        if let reservation = store.reservation {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(.green).frame(maxWidth: .infinity)
            Text("Tu lugar está reservado").font(.title2.bold()).frame(maxWidth: .infinity)
            Text("Confirmación de ejemplo · No es un boleto").font(.caption).foregroundStyle(.secondary)
            Card {
                Text("XOLOS vs ATLAS").font(.title2.bold())
                Text("25 septiembre 2026 · Estadio Caliente").font(.caption)
                Caption(text: reservation.space.zone.uppercased())
                Text("Cajón \(reservation.space.id)").font(.title.bold())
                HStack { Text("Total simulado"); Spacer(); Text("$\(reservation.space.price) MXN").bold() }
                Text("Método: \(reservation.method) · Demo").font(.caption)
                Text("Folio: \(AccessQR.displayID(folio: reservation.folio))").font(.caption).foregroundStyle(.secondary)
            }
            Text("Consulta tu QR y los detalles de llegada desde Mi acceso.").font(.subheadline)
            ActionButton(title: "Ver mi acceso →") { go(.access) }
        } else { Text("Aún no hay una reservación.") }
    }
}
struct AccessView: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        ReservationCloudStatus()
        if let reservation = store.reservation {
            Card {
                Text("RESERVACIÓN REGISTRADA").font(.caption.bold()).foregroundStyle(.green)
                Text("XOLOS vs ATLAS").font(.title2.bold())
                Text("25 SEP 2026 · Estadio Caliente").font(.caption).foregroundStyle(.secondary)
                ReservationQRCode(folio: reservation.folio)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                Text("QR DE XOLOPARK · USO ACADÉMICO").font(.caption.bold()).foregroundStyle(Theme.red).frame(maxWidth: .infinity)
                Text("Identifica tu reservación. La validación de entrada con la maqueta aún no está habilitada.").font(.caption).foregroundStyle(.secondary)
                Text(AccessQR.displayID(folio: reservation.folio)).font(.headline).frame(maxWidth: .infinity)
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Caption(text: reservation.space.zone.uppercased())
                        Text(reservation.space.id).font(.title.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Caption(text: "ACCESO"); Text("Entrada principal").font(.subheadline)
                    }
                }
            }
            Text("Antes de llegar").font(.title3.bold())
            Text("Ten listo tu acceso y sigue la señalización. Este pase de demostración no permite entrar al estadio.").foregroundStyle(.secondary)
        } else {
            Card {
                Label("Todavía no tienes un acceso", systemImage: "ticket").font(.headline)
                Text("Realiza una reservación de demostración desde Inicio para que aparezca aquí.")
            }
        }
    }
}

struct ReservationCloudStatus: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        if store.loading { ProgressView("Consultando reservaciones…") }
        if let message = store.cloudMessage {
            Text(message).font(.caption).foregroundStyle(Theme.red)
        }
        Button("Actualizar disponibilidad", systemImage: "arrow.clockwise") {
            Task { await store.refreshReservations() }
        }.disabled(store.loading || store.saving)
        Text("Pago simulado · Una reservación por cuenta.")
            .font(.caption).foregroundStyle(.secondary)
    }
}
