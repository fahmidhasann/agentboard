import SwiftUI

/// A compact find toolbar overlaid on top of the terminal (⌘F).
///
/// Return / ⌘G find next, ⌘⇧G find previous, Esc closes and clears the highlight. Keeping the
/// navigation shortcuts on the buttons means they're only live while the bar is visible.
struct FindBar: View {
    @Binding var text: String
    @Binding var caseSensitive: Bool
    @Binding var useRegex: Bool
    var focused: FocusState<Bool>.Binding
    var onNext: () -> Void
    var onPrevious: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find", text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
                .frame(minWidth: 160)
                .onSubmit(onNext)

            Divider().frame(height: 16)

            Toggle("Aa", isOn: $caseSensitive)
                .toggleStyle(.button)
                .help("Match case")
            Toggle(".*", isOn: $useRegex)
                .toggleStyle(.button)
                .help("Regular expression")

            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .help("Previous (⌘⇧G)")

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .keyboardShortcut("g", modifiers: .command)
            .help("Next (⌘G)")

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .help("Close (Esc)")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
        .shadow(radius: 4, y: 2)
        .onExitCommand(perform: onClose)
        .onAppear { focused.wrappedValue = true }
    }
}
