import SwiftUI

struct HomeView: View {
    @Environment(DemoStore.self) private var store
    let go: (Route) -> Void
    var body: some View {
        Caption(text: "PRÓXIMOS PARTIDOS").frame(maxWidth: .infinity)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                Button { go(.match) } label: {
                    Image("atlas-poster").resizable().scaledToFit().frame(width: 158)
                }.accessibilityLabel("Ver Xolos contra Atlas, 25 de septiembre")
                Button { go(.match) } label: {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("XOLOS").font(.largeTitle.weight(.black))
                        Text("TU PASIÓN\nTAMBIÉN LLEGA\nEN AUTO").font(.title3.bold())
                        Image(systemName: "car.side.fill").font(.largeTitle)
                        Text("Explora el estacionamiento →").font(.caption)
                    }.foregroundStyle(.white).padding(20).frame(width: 178, height: 207).background(Theme.ink)
                }
            }
        }
        Divider().padding(.vertical, 10)
        Text("Mi próxima reservación").font(.title3.bold())
        ReservationCloudStatus()
        Card {
            if let reservation = store.reservation {
                Text("RESERVACIÓN · DEMO").font(.caption.bold()).foregroundStyle(Theme.red)
                Text("Xolos vs. Atlas").font(.title2.bold())
                Text("25 sep · Estadio Caliente").font(.subheadline).foregroundStyle(.secondary)
                Text("\(reservation.space.zone) · Cajón \(reservation.space.id)").font(.subheadline)
                ActionButton(title: "Ver mi acceso →") { go(.access) }
            } else {
                Label("Todavía no tienes reservaciones", systemImage: "ticket").font(.headline)
                Text("Elige tu lugar para el próximo partido y ten listo tu acceso.").foregroundStyle(.secondary)
                ActionButton(title: "Reservar un cajón →") { go(.match) }
            }
        }
        HStack {
            quick("Mi acceso", "qrcode", .access)
            quick("Mi cuenta", "person.crop.circle", .account)
        }
        Text("Prepara tu visita").font(.title3.bold())
        Card {
            Label("Llega con anticipación", systemImage: "clock")
            Text("Ten listo tu acceso y sigue la señalización del estacionamiento.").font(.subheadline).foregroundStyle(.secondary)
            Label("Revisa tu XoloPass", systemImage: "qrcode.viewfinder")
            Text("Vincúlalo desde Mi cuenta antes de tu visita.").font(.subheadline).foregroundStyle(.secondary)
        }
    }
    private func quick(_ title: String, _ icon: String, _ route: Route) -> some View {
        Button { go(route) } label: {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.subheadline.bold())
            }.frame(maxWidth: .infinity).padding(20).background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
struct MatchView: View {
    let go: (Route) -> Void
    var body: some View {
        Caption(text: "XOLOS VS ATLAS AP2026").frame(maxWidth: .infinity)
        HStack(alignment: .top, spacing: 18) {
            Image("atlas-poster").resizable().scaledToFit().frame(width: 140)
            VStack(alignment: .leading, spacing: 20) {
                Label("25 SEPTIEMBRE 2026", systemImage: "calendar")
                Label("ESTADIO CALIENTE", systemImage: "mappin.and.ellipse")
                ActionButton(title: "RESERVAR") { go(.parking) }
            }.font(.caption.bold()).foregroundStyle(Theme.gold)
        }
        Divider()
        Card {
            Text("Mapa del estacionamiento").font(.headline)
            Text("Conoce las zonas antes de reservar").font(.caption).foregroundStyle(.secondary)
            ParkingMap()
            Text("Mapa ilustrativo basado en la maqueta. Los colores indican zonas, no disponibilidad real.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}
struct ParkingMap: View {
    var body: some View {
        VStack(spacing: 18) {
            Text("XOLOPARK · ACCESO AL ESTADIO").font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(10)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 6))
            HStack(spacing: 3) {
                ForEach(["D-01","D-02","A-01","A-02","A-03","A-04","P-01","P-02"], id: \.self) { id in
                    VStack(spacing: 8) {
                        Text(id).font(.system(size: 8, weight: .bold)).minimumScaleFactor(0.7)
                        Image(systemName: id.hasPrefix("D") ? "figure.roll" : "parkingsign")
                    }.foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 66)
                        .background(id.hasPrefix("D") ? Color.blue : id.hasPrefix("P") ? Theme.red : .gray,
                                    in: RoundedRectangle(cornerRadius: 4))
                }
            }
            HStack {
                Label("ENTRADA", systemImage: "arrow.up"); Spacer()
                Image(systemName: "tree.fill").foregroundStyle(.green); Spacer()
                Label("SALIDA", systemImage: "arrow.down")
            }.font(.system(size: 10, weight: .bold)).padding(.vertical, 26)
            Text("Azul: accesibles · Gris: generales · Rojo: palco").font(.system(size: 9)).foregroundStyle(.secondary)
        }.padding(10).background(.gray.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    }
}
