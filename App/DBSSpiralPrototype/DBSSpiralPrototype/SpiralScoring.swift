import Foundation
import CoreGraphics

struct SpiralSpec {
    let center: CGPoint
    let maxRadius: CGFloat
    let turns: CGFloat
    let corridorWidth: CGFloat

    var thetaMax: CGFloat { turns * 2.0 * .pi }
    var b: CGFloat { maxRadius / max(thetaMax, 0.0001) }

    func idealPoint(theta: CGFloat) -> CGPoint {
        let r = b * theta
        return CGPoint(
            x: center.x + r * cos(theta),
            y: center.y + r * sin(theta)
        )
    }

    func idealPath(sampleCount: Int = 900) -> [CGPoint] {
        guard sampleCount > 1 else { return [] }
        return (0..<sampleCount).map { i in
            let u = CGFloat(i) / CGFloat(sampleCount - 1)
            return idealPoint(theta: u * thetaMax)
        }
    }
}

struct SpiralScoring {
    struct ResidualPoint {
        let t: Double
        let signedRadialError: Double
        let absoluteRadialError: Double
        let isInsideCorridor: Bool
    }

    static func score(samples: [TouchSample], in bounds: CGRect, corridorWidth: CGFloat, turns: CGFloat) -> SpiralScore? {
        guard samples.count >= 8 else { return nil }
        let side = min(bounds.width, bounds.height)
        let maxRadius = max(20.0, side * 0.43)
        let spec = SpiralSpec(center: CGPoint(x: bounds.midX, y: bounds.midY), maxRadius: maxRadius, turns: turns, corridorWidth: corridorWidth)

        let residuals = samples.map { residual(for: CGPoint(x: $0.x, y: $0.y), spec: spec) }
        let absoluteErrors = residuals.map { $0.absoluteRadialError }
        let signedErrors = residuals.map { $0.signedRadialError }
        let inside = residuals.map { $0.isInsideCorridor }

        let sampleCount = samples.count
        let strokeCount = max(1, samples.filter { $0.phase == "began" }.count)
        let duration = max(0.0, (samples.last?.timestamp ?? 0.0) - (samples.first?.timestamp ?? 0.0))
        let percentInside = 100.0 * Double(inside.filter { $0 }.count) / Double(max(1, inside.count))
        let meanAbs = average(absoluteErrors)
        let rms = sqrt(average(signedErrors.map { $0 * $0 }))
        let p95 = percentile(absoluteErrors, p: 0.95)
        let maxAbs = absoluteErrors.max() ?? 0.0
        let pathLength = polylineLength(samples.map { CGPoint(x: $0.x, y: $0.y) })
        let idealLength = polylineLength(spec.idealPath(sampleCount: 900))
        let efficiency = idealLength > 0 ? pathLength / idealLength : 0.0
        let exitCount = boundaryExitCount(insideFlags: inside)
        let spectral = estimatePeakFrequency(samples: samples, signedErrors: signedErrors)

        let quality = qualityAssessment(
            sampleCount: sampleCount,
            duration: duration,
            strokeCount: strokeCount,
            pathEfficiency: efficiency,
            percentInside: percentInside
        )

        return SpiralScore(
            sampleCount: sampleCount,
            strokeCount: strokeCount,
            completionTimeSeconds: duration,
            percentWithinCorridor: percentInside,
            meanAbsoluteRadialErrorPoints: meanAbs,
            rmsRadialErrorPoints: rms,
            percentile95AbsoluteErrorPoints: p95,
            maxAbsoluteErrorPoints: maxAbs,
            pathLengthPoints: pathLength,
            idealPathLengthPoints: idealLength,
            pathEfficiency: efficiency,
            boundaryExitCount: exitCount,
            estimatedPeakFrequencyHz: spectral.peakFrequency,
            tremorPower2to12Hz: spectral.bandPower,
            qualityLabel: quality.label,
            qualityNotes: quality.notes
        )
    }

    /// Computes signed radial error from the nearest turn of an Archimedean spiral.
    /// This is intentionally simple and transparent for early validation work.
    static func residual(for point: CGPoint, spec: SpiralSpec) -> ResidualPoint {
        let dx = point.x - spec.center.x
        let dy = point.y - spec.center.y
        let observedRadius = sqrt(dx * dx + dy * dy)
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2.0 * .pi }

        var bestSignedError = Double.greatestFiniteMagnitude
        let maxTurn = Int(ceil(spec.turns)) + 1
        for k in 0...maxTurn {
            let theta = angle + CGFloat(k) * 2.0 * .pi
            guard theta >= 0, theta <= spec.thetaMax else { continue }
            let expectedRadius = spec.b * theta
            let signed = Double(observedRadius - expectedRadius)
            if abs(signed) < abs(bestSignedError) {
                bestSignedError = signed
            }
        }

        if bestSignedError == Double.greatestFiniteMagnitude {
            // Fallback for points outside the beginning/end angular range.
            let beginningError = Double(observedRadius)
            let endingError = Double(observedRadius - spec.maxRadius)
            bestSignedError = abs(beginningError) < abs(endingError) ? beginningError : endingError
        }

        let absError = abs(bestSignedError)
        return ResidualPoint(
            t: 0,
            signedRadialError: bestSignedError,
            absoluteRadialError: absError,
            isInsideCorridor: absError <= Double(spec.corridorWidth / 2.0)
        )
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0.0, +) / Double(values.count)
    }

    private static func percentile(_ values: [Double], p: Double) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let sorted = values.sorted()
        let clamped = min(max(p, 0), 1)
        let index = Int(round(clamped * Double(sorted.count - 1)))
        return sorted[index]
    }

    private static func polylineLength(_ points: [CGPoint]) -> Double {
        guard points.count > 1 else { return 0.0 }
        var total = 0.0
        for i in 1..<points.count {
            let dx = points[i].x - points[i - 1].x
            let dy = points[i].y - points[i - 1].y
            total += Double(sqrt(dx * dx + dy * dy))
        }
        return total
    }

    private static func boundaryExitCount(insideFlags: [Bool]) -> Int {
        guard insideFlags.count > 1 else { return 0 }
        var count = 0
        for i in 1..<insideFlags.count {
            if insideFlags[i - 1] && !insideFlags[i] { count += 1 }
        }
        return count
    }

    /// Naive, dependency-free frequency estimate from radial residuals.
    /// It resamples approximately to 60 Hz and searches 2-12 Hz in 0.25 Hz steps.
    private static func estimatePeakFrequency(samples: [TouchSample], signedErrors: [Double]) -> (peakFrequency: Double?, bandPower: Double?) {
        guard samples.count == signedErrors.count, samples.count >= 30 else { return (nil, nil) }
        guard let t0 = samples.first?.timestamp, let t1 = samples.last?.timestamp, t1 - t0 >= 1.0 else { return (nil, nil) }

        let duration = t1 - t0
        let sampleRate = 60.0
        let n = max(32, Int(duration * sampleRate))
        var resampled = [Double]()
        resampled.reserveCapacity(n)

        var sourceIndex = 0
        for i in 0..<n {
            let targetT = t0 + Double(i) / sampleRate
            while sourceIndex + 1 < samples.count && samples[sourceIndex + 1].timestamp < targetT {
                sourceIndex += 1
            }
            if sourceIndex + 1 >= samples.count {
                resampled.append(signedErrors.last ?? 0.0)
            } else {
                let leftT = samples[sourceIndex].timestamp
                let rightT = samples[sourceIndex + 1].timestamp
                let leftY = signedErrors[sourceIndex]
                let rightY = signedErrors[sourceIndex + 1]
                let denom = max(0.0001, rightT - leftT)
                let u = min(max((targetT - leftT) / denom, 0), 1)
                resampled.append(leftY + u * (rightY - leftY))
            }
        }

        let mean = average(resampled)
        let centered = resampled.map { $0 - mean }
        var bestFrequency: Double?
        var bestPower = 0.0
        var totalPower = 0.0

        var frequency = 2.0
        while frequency <= 12.0 {
            var real = 0.0
            var imag = 0.0
            for i in 0..<centered.count {
                let t = Double(i) / sampleRate
                let angle = 2.0 * Double.pi * frequency * t
                real += centered[i] * cos(angle)
                imag -= centered[i] * sin(angle)
            }
            let power = (real * real + imag * imag) / Double(centered.count)
            totalPower += power
            if power > bestPower {
                bestPower = power
                bestFrequency = frequency
            }
            frequency += 0.25
        }

        return (bestFrequency, totalPower)
    }

    private static func qualityAssessment(
        sampleCount: Int,
        duration: Double,
        strokeCount: Int,
        pathEfficiency: Double,
        percentInside: Double
    ) -> (label: String, notes: [String]) {
        var notes: [String] = []
        if sampleCount < 40 { notes.append("few samples") }
        if duration < 2.0 { notes.append("very short trial") }
        if strokeCount > 3 { notes.append("multiple pen lifts") }
        if pathEfficiency < 0.45 { notes.append("trace may be incomplete") }
        if pathEfficiency > 3.5 { notes.append("excessively long/erratic path") }
        if percentInside < 5 { notes.append("mostly outside corridor") }

        if notes.isEmpty { return ("Usable", []) }
        if notes.contains("trace may be incomplete") || notes.contains("mostly outside corridor") { return ("Invalid / review", notes) }
        return ("Caution", notes)
    }
}
