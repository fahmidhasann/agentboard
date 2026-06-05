import AppKit

final class GhostTextOverlay: NSView {
    private var text: String = ""
    private var font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func updateFont(_ newFont: NSFont) {
        font = newFont
    }

    func show(text: String, at point: CGPoint, cellHeight: CGFloat) {
        self.text = text

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.textColor.withAlphaComponent(0.35)
        ]
        let size = (text as NSString).size(withAttributes: attrs)

        let y = (superview?.bounds.height ?? 0) - point.y - cellHeight
        frame = CGRect(x: point.x, y: y, width: ceil(size.width), height: ceil(size.height))
        isHidden = false
        needsDisplay = true
    }

    func hide() {
        guard !isHidden else { return }
        isHidden = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard !text.isEmpty else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.textColor.withAlphaComponent(0.35)
        ]
        (text as NSString).draw(at: .zero, withAttributes: attrs)
    }

    override var isFlipped: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
