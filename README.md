# DBS Tremor Spiral Prototype

Research prototype for timestamped, intraoperative tremor assessment during awake DBS surgery for essential tremor. The current app is a native iPadOS SwiftUI/UIKit prototype focused on guided Archimedes spiral tracing, automated scoring, crude side-effect capture, and JSON export.

> **Research-use prototype only.** This app is not a medical device, has not been clinically validated, and must not be used to make autonomous lead-placement, stimulation-programming, diagnostic, or treatment decisions.

## Repository layout

```text
.
├── App/
│   └── DBSSpiralPrototype/          # Xcode project and Swift source
├── docs/
│   └── INTRAOP_ASSESSMENT_SUMMARY.md # 1-2 page literature/design summary
├── README.md                        # intended use, quick start, roadmap
└── .gitignore
```

## Intended use

The prototype is intended to support research and workflow development for **awake DBS intraoperative assessment** in essential tremor. The app records one timestamped trial at a time. Each trial can include:

- guided spiral drawing trace;
- automated spiral score;
- trial phase, such as `Pre-lead baseline`, `Lead inserted / no stim`, `Stim ON`, `Stim OFF`, or `Other`;
- tested hand and optional lead side;
- optional condition note, such as `C2 1.5 mA`, `before stim`, or `after lead insertion`;
- crude clinician-entered side-effect scores;
- free-text clinician note;
- raw stylus samples and derived score fields in JSON export.

The intended workflow is deliberately lightweight: fields can be left blank, each trial is timestamped, and the chronological trial log can be reviewed or exported at the end of the case.

## Current app functionality

The current iPad app includes:

- guided Archimedes spiral tracing;
- full-screen drawing mode;
- Apple Pencil or finger input;
- automated score card with:
  - percent inside corridor;
  - RMS radial error;
  - 95th percentile error;
  - boundary exits;
  - completion time;
  - stroke count;
  - path efficiency;
  - approximate peak frequency;
  - quality label and notes;
- adjustable corridor width;
- adjustable number of spiral turns;
- tested hand selector;
- optional lead side selector;
- phase selector;
- optional condition note;
- quick side-effect scoring for:
  - paresthesia;
  - dysarthria;
  - ataxia/dysmetria;
  - motor pull/capsular effect;
  - other;
- free-text clinician note;
- `Done — Save Trial` workflow;
- chronological saved trial history;
- current-trial JSON export;
- all-trials JSON export;
- local autosave snapshot.

## Scoring overview

The app stores raw stylus points in a canonical coordinate system and computes interpretable geometric and temporal metrics. Spiral scoring is based on deviation from the ideal guided spiral and corridor membership. The most useful current metrics are:

- **Percent inside corridor:** percentage of recorded samples inside the spiral corridor.
- **RMS radial error:** root-mean-square radial deviation from the ideal spiral path.
- **95th percentile absolute error:** high-end tracing deviation.
- **Boundary exits:** number of out-of-corridor episodes.
- **Completion time:** time from first to last stylus/finger sample.
- **Stroke count:** rough pen-lift count.
- **Path efficiency:** drawn path length divided by ideal path length.
- **Approximate peak frequency:** simple tremor-band estimate derived from residuals.

These scores should be interpreted as task-specific measurements, not as comprehensive tremor severity, clinical outcome, or lead-placement guidance.

## Running the app

Open the Xcode project:

```text
App/DBSSpiralPrototype/DBSSpiralPrototype.xcodeproj
```

Then select an iPad simulator and run:

```text
Product > Clean Build Folder
Product > Run
```

For physical iPad testing, use either a local Mac with Xcode and a cable, or a paid Apple Developer Program account with TestFlight distribution. A free Personal Team is usually enough for local cable-based development testing, but not for TestFlight/App Store Connect distribution.

## Suggested intraoperative workflow

1. Open the app before the first trial.
2. Select the phase, tested hand, and optional lead side.
3. Enter a brief condition note only when useful.
4. Tap the expand button to draw the spiral full-screen.
5. Collapse back to the main trial screen.
6. Optionally enter crude side-effect scores and a note.
7. Tap **Done — Save Trial**.
8. Repeat across the case.
9. Export all trials as JSON at the end.

## Side-effect scoring convention

Side-effect buttons use a deliberately crude intraoperative convention:

| Value | Meaning |
|---:|---|
| blank | not assessed / not entered |
| 0 | absent |
| 1 | mild |
| 2 | moderate |
| 3 | severe |

This is meant for fast intraoperative note-taking, not formal neurological adverse-event grading.

## Data and privacy notes

This prototype is not hardened for clinical deployment. Before any real clinical or research use, add appropriate institutional review, privacy controls, encryption, data handling policies, audit logs, and validated export procedures. Avoid entering protected health information into prototype builds unless explicitly approved by the relevant IRB/institutional process.

## Next steps / to-do list

### Near-term app improvements

- Add a case/session setup screen with non-PHI study ID and optional laterality fields.
- Add a clear `Mark as baseline` function and baseline-vs-current percent-change display.
- Add CSV export in addition to JSON.
- Add a case summary screen with chronological trial table and best-noted conditions.
- Add trial invalidation/QC override, such as `wrong hand`, `interrupted`, `patient braced differently`, or `stylus artifact`.
- Add optional amplitude/contact/frequency/pulse-width fields without requiring them for every trial.
- Add export filename customization using study ID and date.
- Add local persistence across app restarts with visible recovery of unsaved trials.

### Next motor tasks

- Add free spiral drawing.
- Add curved tunnel/path tracing with percent-inside-corridor score.
- Add straight-line tracing.
- Add short glyph/handwriting task.
- Add target dwell or dot approximation only after the core workflow is stable.

### Validation and research tasks

- Verify scoring with simulated traces.
- Test repeatability in healthy volunteers.
- Compare app metrics against accepted clinical tremor scales in ET patients.
- Run an intraoperative feasibility study measuring completion rate, time per trial, invalid-trial rate, clinician adoption, and sensitivity to stimulation changes.
- Preserve raw trace data for retrospective algorithm development.

### Safety/regulatory tasks

- Keep labeling as research-use only until validation and regulatory review are complete.
- Avoid any “best contact,” “best lead location,” or “recommended stimulation setting” output.
- Add hardware/device/app version recording to every trial.
- Define approved device/stylus/screen-protector configurations.
- Add data-security, audit-log, and change-control processes before real deployment.
