import SwiftUI
import UIKit
import Foundation

struct ContentView: View {
    @State private var subjectID = "CASE-001"
    @State private var phase = "Pre-lead baseline"
    @State private var handTested = "Right"
    @State private var leadSide = ""
    @State private var conditionNote = ""
    @State private var clinicianNote = ""
    @State private var sideEffects = TrialSideEffects()

    @State private var samples: [TouchSample] = []
    @State private var score: SpiralScore?
    @State private var scoredCanvasSize: CGSize = .zero
    @State private var resetToken = UUID()
    @State private var corridorWidth: CGFloat = 34
    @State private var turns: CGFloat = 3.25
    @State private var showingFullScreenSpiral = false

    @State private var savedTrials: [IntraopTrialRecord] = []
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var statusMessage = "No saved trials yet."

    private let phaseOptions = [
        "Pre-lead baseline",
        "Lead inserted / no stim",
        "Stim ON",
        "Stim OFF",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    instructionPanel
                    spiralCanvasPanel
                }
                .padding(.leading)
                .padding(.vertical)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        intraopHeaderPanel
                        spiralSettingsPanel
                        scorePanel
                        quickEffectsPanel
                        notePanel
                        actionPanel
                        historyPanel
                        scoringDefinitionPanel
                    }
                    .padding(.trailing)
                    .padding(.vertical)
                    .frame(width: 430)
                }
            }
            .navigationTitle("DBS Spiral Intra-op Recorder")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .fullScreenCover(isPresented: $showingFullScreenSpiral) {
                FullScreenSpiralDrawingView(
                    samples: $samples,
                    score: $score,
                    scoredCanvasSize: $scoredCanvasSize,
                    resetToken: resetToken,
                    corridorWidth: corridorWidth,
                    turns: turns,
                    trialNumber: savedTrials.count + 1,
                    phase: phase,
                    handTested: handTested,
                    conditionNote: conditionNote,
                    onDone: { showingFullScreenSpiral = false },
                    onClear: { clearDrawingOnly() }
                )
            }
        }
    }

    private var instructionPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Guided spiral task")
                .font(.title2.bold())
            Text("Trace from the green dot to the red dot while staying inside the teal corridor. Use the expand button in the upper-right of the drawing area for full-screen drawing. When the trial is complete, optionally enter quick effects/notes, then tap Done — Save Trial.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var spiralCanvasPanel: some View {
        ZStack(alignment: .topTrailing) {
            SpiralCanvasView(
                samples: $samples,
                score: $score,
                scoredCanvasSize: $scoredCanvasSize,
                resetToken: resetToken,
                corridorWidth: corridorWidth,
                turns: turns
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                showingFullScreenSpiral = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.title3.weight(.semibold))
                    .padding(12)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand spiral to full screen")
            .padding(14)
        }
    }

    private var intraopHeaderPanel: some View {
        GroupBox("Intra-op trial") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Next trial")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("#\(savedTrials.count + 1)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                TextField("Case / subject ID optional", text: $subjectID)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Phase", selection: $phase) {
                        ForEach(phaseOptions, id: \.self) { option in
                            Text(shortPhaseLabel(option)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hand tested")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Hand", selection: $handTested) {
                            Text("Right").tag("Right")
                            Text("Left").tag("Left")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lead side")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Lead side", selection: $leadSide) {
                            Text("—").tag("")
                            Text("L").tag("Left")
                            Text("R").tag("Right")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                TextField("Condition / setting note optional, e.g. C2 1.5 mA", text: $conditionNote)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var spiralSettingsPanel: some View {
        GroupBox("Spiral settings") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Corridor width: \(Int(corridorWidth)) pt")
                    Slider(value: $corridorWidth, in: 18...70, step: 2)
                }
                VStack(alignment: .leading) {
                    Text("Spiral turns: \(String(format: "%.2f", Double(turns)))")
                    Slider(value: $turns, in: 2.0...4.5, step: 0.25)
                }
            }
        }
    }

    private var scorePanel: some View {
        GroupBox("Automated score") {
            VStack(alignment: .leading, spacing: 8) {
                if let score {
                    ScoreRow(label: "Sample count", value: "\(score.sampleCount)")
                    ScoreRow(label: "Percent inside corridor", value: String(format: "%.1f%%", score.percentWithinCorridor))
                    ScoreRow(label: "Mean absolute radial error", value: String(format: "%.1f pt", score.meanAbsoluteRadialErrorPoints))
                    ScoreRow(label: "RMS radial error", value: String(format: "%.1f pt", score.rmsRadialErrorPoints))
                    ScoreRow(label: "95th percentile error", value: String(format: "%.1f pt", score.percentile95AbsoluteErrorPoints))
                    ScoreRow(label: "Maximum absolute error", value: String(format: "%.1f pt", score.maxAbsoluteErrorPoints))
                    ScoreRow(label: "Boundary exits", value: "\(score.boundaryExitCount)")
                    ScoreRow(label: "Completion time", value: String(format: "%.2f s", score.completionTimeSeconds))
                    ScoreRow(label: "Stroke count", value: "\(score.strokeCount)")
                    ScoreRow(label: "Path length", value: String(format: "%.0f pt", score.pathLengthPoints))
                    ScoreRow(label: "Ideal path length", value: String(format: "%.0f pt", score.idealPathLengthPoints))
                    ScoreRow(label: "Path efficiency", value: String(format: "%.2f×", score.pathEfficiency))
                    ScoreRow(label: "Peak frequency", value: score.estimatedPeakFrequencyHz.map { String(format: "%.2f Hz", $0) } ?? "n/a")
                    ScoreRow(label: "Tremor power 2–12 Hz", value: score.tremorPower2to12Hz.map { String(format: "%.1f", $0) } ?? "n/a")
                    if scoredCanvasSize.width > 0, scoredCanvasSize.height > 0 {
                        ScoreRow(label: "Canvas size", value: String(format: "%.0f × %.0f pt", scoredCanvasSize.width, scoredCanvasSize.height))
                    }
                    ScoreRow(label: "Quality", value: score.qualityLabel)
                    if !score.qualityNotes.isEmpty {
                        Text(score.qualityNotes.joined(separator: ", "))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Draw at least part of the spiral to generate a score.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quickEffectsPanel: some View {
        GroupBox("Quick effects, optional") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Blank = not assessed. 0 = absent. 1/2/3 = mild/moderate/severe.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                SeverityControl(title: "Paresthesia", value: $sideEffects.paresthesia)
                SeverityControl(title: "Dysarthria", value: $sideEffects.dysarthria)
                SeverityControl(title: "Ataxia/dysmetria", value: $sideEffects.ataxiaDysmetria)
                SeverityControl(title: "Motor pull", value: $sideEffects.motorPullCapsular)
                SeverityControl(title: "Other", value: $sideEffects.other)

                HStack(spacing: 10) {
                    Button("All absent") {
                        sideEffects = TrialSideEffects(
                            paresthesia: 0,
                            dysarthria: 0,
                            ataxiaDysmetria: 0,
                            motorPullCapsular: 0,
                            other: 0
                        )
                    }
                    .buttonStyle(.bordered)

                    Button("Clear effects") {
                        sideEffects = TrialSideEffects()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var notePanel: some View {
        GroupBox("Clinician note, optional") {
            TextEditor(text: $clinicianNote)
                .frame(minHeight: 70)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.25))
                )
        }
    }

    private var actionPanel: some View {
        GroupBox("Actions") {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    saveCurrentTrial()
                } label: {
                    Label("Done — Save Trial", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(samples.isEmpty)

                HStack(spacing: 10) {
                    Button(role: .destructive) {
                        clearCurrentTrial(clearContext: false)
                    } label: {
                        Label("Clear current", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        exportCurrentTrial()
                    } label: {
                        Label("Export current", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(samples.isEmpty)
                }

                Button {
                    exportAllTrials()
                } label: {
                    Label("Export all saved trials", systemImage: "tray.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(savedTrials.isEmpty)

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var historyPanel: some View {
        GroupBox("Saved trial history") {
            VStack(alignment: .leading, spacing: 8) {
                if savedTrials.isEmpty {
                    Text("Saved trials will appear here in timestamp order.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(savedTrials.suffix(8).reversed()) { trial in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("#\(trial.trialNumber)")
                                    .fontWeight(.semibold)
                                Text(timeOnly(trial.createdAt))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let percent = trial.score?.percentWithinCorridor {
                                    Text(String(format: "%.1f%% inside", percent))
                                        .monospacedDigit()
                                } else {
                                    Text("no score")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(historySubtitle(for: trial))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
            }
            .font(.callout)
        }
    }

    private var scoringDefinitionPanel: some View {
        GroupBox("Prototype scoring") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Research/development prototype only. The app records timestamped intra-op trials and transparent component metrics; it does not recommend lead position or stimulation settings.")
                Text("Primary endpoint: percent of raw samples within the shaded corridor. Secondary endpoints include RMS error, 95th percentile error, boundary exits, path efficiency, and an approximate 2–12 Hz residual-frequency peak.")
                Text("For best comparability, use the same drawing mode and iPad orientation across trials. The JSON export now records the scoring canvas size.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func saveCurrentTrial() {
        let record = makeCurrentTrialRecord()
        savedTrials.append(record)
        saveCaseSnapshotToDocuments()
        statusMessage = "Saved trial #\(record.trialNumber) at \(timeOnly(record.createdAt))."
        clearCurrentTrial(clearContext: false)
    }

    private func exportCurrentTrial() {
        let record = makeCurrentTrialRecord()
        writeJSON(record, filePrefix: "spiral_current_trial")
    }

    private func exportAllTrials() {
        let export = CaseExport(
            appName: "DBS Spiral Intra-op Recorder",
            schemaVersion: "0.3",
            exportedAt: Date(),
            subjectID: optionalString(subjectID),
            savedTrialCount: savedTrials.count,
            trials: savedTrials
        )
        writeJSON(export, filePrefix: "spiral_case_export")
    }

    private func makeCurrentTrialRecord() -> IntraopTrialRecord {
        IntraopTrialRecord(
            id: UUID(),
            trialNumber: savedTrials.count + 1,
            createdAt: Date(),
            subjectID: optionalString(subjectID),
            phase: optionalString(phase),
            handTested: optionalString(handTested),
            leadSide: optionalString(leadSide),
            conditionNote: optionalString(conditionNote),
            clinicianNote: optionalString(clinicianNote),
            corridorWidthPoints: corridorWidth,
            spiralTurns: turns,
            canvasWidthPoints: scoredCanvasSize.width > 0 ? scoredCanvasSize.width : nil,
            canvasHeightPoints: scoredCanvasSize.height > 0 ? scoredCanvasSize.height : nil,
            drawingCoordinateSpace: "canonical_1000x1000",
            sideEffects: sideEffects,
            samples: samples,
            score: score,
            appName: "DBS Spiral Intra-op Recorder",
            appVersion: appVersionString(),
            schemaVersion: "0.3"
        )
    }

    private func clearCurrentTrial(clearContext: Bool) {
        clearDrawingOnly()
        sideEffects = TrialSideEffects()
        clinicianNote = ""
        if clearContext {
            conditionNote = ""
            leadSide = ""
        }
    }

    private func clearDrawingOnly() {
        samples.removeAll()
        score = nil
        scoredCanvasSize = .zero
        resetToken = UUID()
    }

    private func saveCaseSnapshotToDocuments() {
        let export = CaseExport(
            appName: "DBS Spiral Intra-op Recorder",
            schemaVersion: "0.3",
            exportedAt: Date(),
            subjectID: optionalString(subjectID),
            savedTrialCount: savedTrials.count,
            trials: savedTrials
        )
        do {
            let data = try encodedJSON(export)
            let url = documentsDirectory().appendingPathComponent("DBSSpiral_case_autosave.json")
            try data.write(to: url, options: .atomic)
        } catch {
            statusMessage = "Autosave failed: \(error.localizedDescription)"
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, filePrefix: String) {
        do {
            let data = try encodedJSON(value)
            let safeID = (optionalString(subjectID) ?? "case").replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)_\(safeID)_\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url, options: .atomic)
            exportURL = url
            showingShareSheet = true
            statusMessage = "Prepared JSON export."
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func encodedJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func optionalString(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func shortPhaseLabel(_ value: String) -> String {
        switch value {
        case "Pre-lead baseline": return "Pre-lead"
        case "Lead inserted / no stim": return "Lead/no stim"
        case "Stim ON": return "Stim ON"
        case "Stim OFF": return "Stim OFF"
        default: return "Other"
        }
    }

    private func historySubtitle(for trial: IntraopTrialRecord) -> String {
        let phaseText = trial.phase ?? "phase blank"
        let handText = trial.handTested.map { "hand \($0)" } ?? "hand blank"
        let conditionText = trial.conditionNote ?? "condition blank"
        let effectsText = trial.sideEffects.compactSummary
        return "\(phaseText) • \(handText) • \(conditionText) • \(effectsText)"
    }

    private func timeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct FullScreenSpiralDrawingView: View {
    @Binding var samples: [TouchSample]
    @Binding var score: SpiralScore?
    @Binding var scoredCanvasSize: CGSize

    let resetToken: UUID
    let corridorWidth: CGFloat
    let turns: CGFloat
    let trialNumber: Int
    let phase: String
    let handTested: String
    let conditionNote: String
    let onDone: () -> Void
    let onClear: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let side = max(280, min(geometry.size.width - 48, geometry.size.height - 170))

            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full-screen spiral")
                            .font(.title2.bold())
                        Text("Trial #\(trialNumber) • \(phase) • hand \(handTested)\(conditionNote.isEmpty ? "" : " • \(conditionNote)")")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        onClear()
                    } label: {
                        Label("Clear", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        onDone()
                    } label: {
                        Label("Collapse", systemImage: "arrow.down.right.and.arrow.up.left")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                SpiralCanvasView(
                    samples: $samples,
                    score: $score,
                    scoredCanvasSize: $scoredCanvasSize,
                    resetToken: resetToken,
                    corridorWidth: corridorWidth,
                    turns: turns
                )
                .frame(width: side, height: side)

                HStack(spacing: 12) {
                    if let score {
                        FullScreenMetric(label: "Inside", value: String(format: "%.1f%%", score.percentWithinCorridor))
                        FullScreenMetric(label: "RMS", value: String(format: "%.1f pt", score.rmsRadialErrorPoints))
                        FullScreenMetric(label: "Time", value: String(format: "%.2f s", score.completionTimeSeconds))
                        FullScreenMetric(label: "QC", value: score.qualityLabel)
                    } else {
                        Text("Trace the spiral. Collapse when finished to enter effects/notes and save the trial.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        onDone()
                    } label: {
                        Label("Done drawing", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(samples.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

private struct FullScreenMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ScoreRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .fontWeight(.semibold)
        }
        .font(.callout)
    }
}

private struct SeverityControl: View {
    let title: String
    @Binding var value: Int?

    private let options: [(label: String, value: Int?)] = [
        ("—", nil),
        ("0", 0),
        ("1", 1),
        ("2", 2),
        ("3", 3)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(0..<options.count, id: \.self) { index in
                    let option = options[index]
                    Button(option.label) {
                        value = option.value
                    }
                    .font(.callout.monospacedDigit())
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .tint(value == option.value ? .accentColor : .secondary)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
