import SwiftUI
import UIKit

/// SwiftUI wrapper around the custom UIKit drawing surface.
///
/// The stored sample coordinates use a stable 1000 x 1000 drawing coordinate space.
/// That lets the same trial be drawn full-screen and then previewed later in the smaller
/// main-screen canvas without changing the score or distorting the saved raw trace.
struct SpiralCanvasView: UIViewRepresentable {
    @Binding var samples: [TouchSample]
    @Binding var score: SpiralScore?
    @Binding var scoredCanvasSize: CGSize

    let resetToken: UUID
    let corridorWidth: CGFloat
    let turns: CGFloat

    func makeUIView(context: Context) -> SpiralCanvasUIView {
        let view = SpiralCanvasUIView()
        view.corridorWidth = corridorWidth
        view.turns = turns
        view.replaceSamplesIfNeeded(samples)
        view.onSamplesChanged = { newSamples in
            DispatchQueue.main.async { self.samples = newSamples }
        }
        view.onScoreChanged = { newScore, canvasSize in
            DispatchQueue.main.async {
                self.score = newScore
                self.scoredCanvasSize = canvasSize
            }
        }
        context.coordinator.lastResetToken = resetToken
        return view
    }

    func updateUIView(_ uiView: SpiralCanvasUIView, context: Context) {
        uiView.corridorWidth = corridorWidth
        uiView.turns = turns
        uiView.replaceSamplesIfNeeded(samples)
        if context.coordinator.lastResetToken != resetToken {
            uiView.clear()
            context.coordinator.lastResetToken = resetToken
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastResetToken = UUID()
    }
}

final class SpiralCanvasUIView: UIView {
    static let canonicalSide: CGFloat = 1000
    static var canonicalBounds: CGRect { CGRect(x: 0, y: 0, width: canonicalSide, height: canonicalSide) }

    var corridorWidth: CGFloat = 68 {
        didSet {
            guard corridorWidth != oldValue else { return }
            setNeedsDisplay()
            updateScore(force: true)
        }
    }
    var turns: CGFloat = 3.25 {
        didSet {
            guard turns != oldValue else { return }
            setNeedsDisplay()
            updateScore(force: true)
        }
    }

    var onSamplesChanged: (([TouchSample]) -> Void)?
    var onScoreChanged: ((SpiralScore?, CGSize) -> Void)?

    private var samples: [TouchSample] = []
    private var lastScoringTime: TimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .systemBackground
        isMultipleTouchEnabled = false
        isOpaque = true
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor
    }

    func clear() {
        samples.removeAll()
        onSamplesChanged?(samples)
        onScoreChanged?(nil, bounds.size)
        setNeedsDisplay()
    }

    func replaceSamplesIfNeeded(_ externalSamples: [TouchSample]) {
        guard needsReplacing(with: externalSamples) else { return }
        samples = externalSamples
        setNeedsDisplay()
        updateScore(force: true)
    }

    private func needsReplacing(with externalSamples: [TouchSample]) -> Bool {
        if samples.count != externalSamples.count { return true }
        guard let localLast = samples.last, let externalLast = externalSamples.last else {
            return samples.isEmpty != externalSamples.isEmpty
        }
        return localLast.id != externalLast.id || abs(localLast.x - externalLast.x) > 0.001 || abs(localLast.y - externalLast.y) > 0.001
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawTemplate(in: rect)
        drawUserTrace()
    }

    private func currentSpec() -> SpiralSpec {
        let bounds = Self.canonicalBounds
        return SpiralSpec(
            center: CGPoint(x: bounds.midX, y: bounds.midY),
            maxRadius: max(20, Self.canonicalSide * 0.43),
            turns: turns,
            corridorWidth: corridorWidth
        )
    }

    private func drawingRect() -> CGRect {
        let inset: CGFloat = 8
        let availableWidth = max(1, bounds.width - inset * 2)
        let availableHeight = max(1, bounds.height - inset * 2)
        let side = max(1, min(availableWidth, availableHeight))
        return CGRect(
            x: bounds.midX - side / 2,
            y: bounds.midY - side / 2,
            width: side,
            height: side
        )
    }

    private func viewPoint(fromCanonical point: CGPoint) -> CGPoint {
        let rect = drawingRect()
        return CGPoint(
            x: rect.minX + (point.x / Self.canonicalSide) * rect.width,
            y: rect.minY + (point.y / Self.canonicalSide) * rect.height
        )
    }

    private func canonicalPoint(fromView point: CGPoint) -> CGPoint {
        let rect = drawingRect()
        return CGPoint(
            x: ((point.x - rect.minX) / max(rect.width, 1)) * Self.canonicalSide,
            y: ((point.y - rect.minY) / max(rect.height, 1)) * Self.canonicalSide
        )
    }

    private func viewLength(fromCanonical length: CGFloat) -> CGFloat {
        let rect = drawingRect()
        return length / Self.canonicalSide * rect.width
    }

    private func drawTemplate(in rect: CGRect) {
        let spec = currentSpec()
        let canonicalPoints = spec.idealPath(sampleCount: 900)
        let points = canonicalPoints.map { viewPoint(fromCanonical: $0) }
        guard points.count > 1 else { return }

        let corridor = UIBezierPath()
        corridor.move(to: points[0])
        for p in points.dropFirst() { corridor.addLine(to: p) }
        corridor.lineCapStyle = .round
        corridor.lineJoinStyle = .round
        corridor.lineWidth = max(6, viewLength(fromCanonical: corridorWidth))
        UIColor.systemTeal.withAlphaComponent(0.14).setStroke()
        corridor.stroke()

        let centerLine = UIBezierPath()
        centerLine.move(to: points[0])
        for p in points.dropFirst() { centerLine.addLine(to: p) }
        centerLine.lineCapStyle = .round
        centerLine.lineJoinStyle = .round
        centerLine.lineWidth = max(1.5, viewLength(fromCanonical: 2.5))
        UIColor.systemTeal.withAlphaComponent(0.88).setStroke()
        centerLine.stroke()

        drawDot(points.first!, radius: max(7, viewLength(fromCanonical: 12)), color: .systemGreen)
        drawDot(points.last!, radius: max(7, viewLength(fromCanonical: 12)), color: .systemRed)
    }

    private func drawDot(_ point: CGPoint, radius: CGFloat, color: UIColor) {
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        color.setFill()
        UIBezierPath(ovalIn: rect).fill()
    }

    private func drawUserTrace() {
        guard !samples.isEmpty else { return }
        let path = UIBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = max(2.5, min(6, viewLength(fromCanonical: 7)))

        var started = false
        for sample in samples {
            let point = viewPoint(fromCanonical: CGPoint(x: sample.x, y: sample.y))
            if sample.phase == "began" || !started {
                path.move(to: point)
                started = true
            } else {
                path.addLine(to: point)
            }
        }

        UIColor.label.withAlphaComponent(0.88).setStroke()
        path.stroke()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        captureTouches(touches, with: event, forcedPhase: "began")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        captureTouches(touches, with: event, forcedPhase: "moved")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        captureTouches(touches, with: event, forcedPhase: "ended")
        updateScore(force: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        captureTouches(touches, with: event, forcedPhase: "cancelled")
        updateScore(force: true)
    }

    private func captureTouches(_ touches: Set<UITouch>, with event: UIEvent?, forcedPhase: String) {
        guard let touch = touches.first else { return }
        let allTouches = event?.coalescedTouches(for: touch) ?? [touch]
        for coalescedTouch in allTouches {
            appendSample(from: coalescedTouch, phase: forcedPhase)
        }
        onSamplesChanged?(samples)
        updateScore(force: false)
        setNeedsDisplay()
    }

    private func appendSample(from touch: UITouch, phase: String) {
        let point = canonicalPoint(fromView: touch.location(in: self))
        let timestamp = touch.timestamp
        if let last = samples.last, timestamp <= last.timestamp, phase != "began" {
            return
        }
        samples.append(
            TouchSample(
                x: point.x,
                y: point.y,
                timestamp: timestamp,
                force: touch.force,
                maximumPossibleForce: touch.maximumPossibleForce,
                phase: phase,
                inputType: inputTypeString(touch.type)
            )
        )
    }

    private func inputTypeString(_ type: UITouch.TouchType) -> String {
        switch type {
        case .direct: return "finger/direct"
        case .indirect: return "indirect"
        case .pencil: return "apple_pencil"
        case .indirectPointer: return "indirect_pointer"
        @unknown default: return "unknown"
        }
    }

    private func updateScore(force: Bool) {
        let now = ProcessInfo.processInfo.systemUptime
        guard force || now - lastScoringTime > 0.25 else { return }
        lastScoringTime = now
        let nextScore = SpiralScoring.score(
            samples: samples,
            in: Self.canonicalBounds,
            corridorWidth: corridorWidth,
            turns: turns
        )
        onScoreChanged?(nextScore, bounds.size)
    }
}
