import SwiftUI

struct Card<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
struct ActionButton: View {
    let title: String
    var color: Color = Theme.red
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline.bold()).frame(maxWidth: .infinity).frame(minHeight: 50)
        }.foregroundStyle(.white)
            .background(disabled ? .gray : color, in: RoundedRectangle(cornerRadius: 12))
            .disabled(disabled)
    }
}
struct Caption: View {
    let text: String
    var body: some View { Text(text).font(.caption.bold()).tracking(0.6).foregroundStyle(Theme.gold) }
}
struct DemoFooter: View {
    var body: some View {
        Text("CUENTAS REALES · PAGOS Y PASES DE DEMOSTRACIÓN")
            .font(.system(size: 10)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.vertical, 12)
    }
}
extension View {
    func fieldStyle() -> some View {
        self.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.2)))
            .autocorrectionDisabled()
    }
}
struct BrandHeader: View {
    let title: String
    var back: (() -> Void)?
    let menu: () -> Void
    var body: some View {
        ZStack(alignment: .leading) {
            Theme.red
            Image("header-xolo").resizable().scaledToFill()
                .frame(width: 145, height: 154).clipped().accessibilityHidden(true)
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    if let back {
                        Button(action: back) { Image(systemName: "chevron.left").padding(10) }
                            .accessibilityLabel("Volver")
                    }
                    Spacer()
                    Button(action: menu) { Image(systemName: "line.3.horizontal").padding(10) }
                        .accessibilityLabel("Abrir menú")
                }
                Text(title).font(.system(size: 25, weight: .heavy))
                    .multilineTextAlignment(.trailing).minimumScaleFactor(0.65).lineLimit(2)
                    .padding(.leading, 138)
                Spacer(minLength: 0)
            }.padding(.horizontal, 18).padding(.top, 8)
        }.foregroundStyle(.white).frame(height: 154).clipped()
    }
}
