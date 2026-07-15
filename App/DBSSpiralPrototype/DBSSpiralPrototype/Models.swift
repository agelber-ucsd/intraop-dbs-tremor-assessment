import Foundation
import CoreGraphics

/// One raw touch/stylus sample from the drawing surface.
struct TouchSample: Identifiable, Codable, Equatable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let timestamp: TimeInterval
    let force: CGFloat
    let maximumPossibleForce: CGFloat
    let phase: String
    let inputType: String

    init(
        id: UUID = UUID(),
        x: CGFloat,
        y: CGFloat,
        timestamp: TimeInterval,
        force: CGFloat,
        maximumPossibleForce: CGFloat,
        phase: String,
        inputType: String
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.timestamp = timestamp
        self.force = force
        self.maximumPossibleForce = maximumPossibleForce
        self.phase = phase
        self.inputType = inputType
    }
}

/// Summary score produced from a completed or partially completed spiral trace.
struct SpiralScore: Codable, Equatable {
    let sampleCount: Int
    let strokeCount: Int
    let completionTimeSeconds: Double
    let percentWithinCorridor: Double
    let meanAbsoluteRadialErrorPoints: Double
    let rmsRadialErrorPoints: Double
    let percentile95AbsoluteErrorPoints: Double
    let maxAbsoluteErrorPoints: Double
    let pathLengthPoints: Double
    let idealPathLengthPoints: Double
    let pathEfficiency: Double
    let boundaryExitCount: Int
    let estimatedPeakFrequencyHz: Double?
    let tremorPower2to12Hz: Double?
    let qualityLabel: String
    let qualityNotes: [String]

    var compactSummary: String {
        let frequency = estimatedPeakFrequencyHz.map { String(format: "%.2f Hz", $0) } ?? "n/a"
        return "Inside: \(String(format: "%.1f", percentWithinCorridor))% | RMS error: \(String(format: "%.1f", rmsRadialErrorPoints)) pt | Peak freq: \(frequency) | Quality: \(qualityLabel)"
    }
}

/// Crude clinician-entered side-effect scores for one intraoperative trial.
/// nil means "not entered"; 0 means explicitly absent; 1/2/3 mean mild/moderate/severe.
struct TrialSideEffects: Codable, Equatable {
    var paresthesia: Int?
    var dysarthria: Int?
    var ataxiaDysmetria: Int?
    var motorPullCapsular: Int?
    var other: Int?

    init(
        paresthesia: Int? = nil,
        dysarthria: Int? = nil,
        ataxiaDysmetria: Int? = nil,
        motorPullCapsular: Int? = nil,
        other: Int? = nil
    ) {
        self.paresthesia = paresthesia
        self.dysarthria = dysarthria
        self.ataxiaDysmetria = ataxiaDysmetria
        self.motorPullCapsular = motorPullCapsular
        self.other = other
    }

    var hasAnyEntry: Bool {
        [paresthesia, dysarthria, ataxiaDysmetria, motorPullCapsular, other].contains { $0 != nil }
    }

    var maxSeverity: Int? {
        [paresthesia, dysarthria, ataxiaDysmetria, motorPullCapsular, other].compactMap { $0 }.max()
    }

    var compactSummary: String {
        var parts: [String] = []
        appendEffect("Paresthesia", paresthesia, to: &parts)
        appendEffect("Dysarthria", dysarthria, to: &parts)
        appendEffect("Ataxia/dysmetria", ataxiaDysmetria, to: &parts)
        appendEffect("Motor pull", motorPullCapsular, to: &parts)
        appendEffect("Other", other, to: &parts)
        return parts.isEmpty ? "effects blank" : parts.joined(separator: ", ")
    }

    private func appendEffect(_ label: String, _ value: Int?, to parts: inout [String]) {
        guard let value else { return }
        parts.append("\(label) \(value)")
    }
}

/// Full export record for one intraoperative trial.
struct IntraopTrialRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let trialNumber: Int
    let createdAt: Date
    let subjectID: String?
    let phase: String?
    let handTested: String?
    let leadSide: String?
    let conditionNote: String?
    let clinicianNote: String?
    let corridorWidthPoints: CGFloat
    let spiralTurns: CGFloat
    let canvasWidthPoints: CGFloat?
    let canvasHeightPoints: CGFloat?
    let drawingCoordinateSpace: String
    let sideEffects: TrialSideEffects
    let samples: [TouchSample]
    let score: SpiralScore?
    let appName: String
    let appVersion: String
    let schemaVersion: String
}

/// Export container for all saved trials from one case/session.
struct CaseExport: Codable {
    let appName: String
    let schemaVersion: String
    let exportedAt: Date
    let subjectID: String?
    let savedTrialCount: Int
    let trials: [IntraopTrialRecord]
}

/// Backward-compatible export record for one current trial.
typealias TrialExport = IntraopTrialRecord
