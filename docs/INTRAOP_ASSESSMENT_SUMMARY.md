# Intraoperative Tremor Assessment for Awake DBS in Essential Tremor

This summary is derived from the longer review dossier, *Tablet-Based Quantitative Assessment of Essential Tremor During Awake Deep Brain Stimulation: Literature Review and Design Proposal for an iPad Tremor Testing App*. It focuses on which intraoperative assessments are best supported, how they are used, and which proposed app tasks remain investigational.

## Bottom line

Awake DBS assessment for essential tremor still depends heavily on clinician observation of immediate tremor benefit versus stimulation-induced adverse effects. The most defensible initial app design is therefore not an autonomous decision tool, but a transparent measurement aid that records standardized task performance, raw traces, timestamps, stimulation context, side effects, and optional clinician notes.

The strongest task families for an initial iPad prototype are familiar bedside tasks: spiral drawing/tracing, writing or glyph copying, straight-line or path tracing, and clinician-guided postural/kinetic observation. Objective accelerometry and wearable sensing have stronger evidence as quantitative motion-capture methods, but they add hardware and operating-room integration burden. Curved tunnel tracing, target dwell, and Fitts-style target acquisition are promising but should be labeled investigational for ET DBS until validated prospectively.

## Validated or clinically established assessment families

| Assessment family | Current support | Intra-op use | Limitations |
|---|---|---|---|
| **Clinician-rated tremor examination** | Standard clinical practice; embedded in tremor scales and DBS workflows. | Rapid comparison of tremor suppression and side effects across lead/contact/stimulation conditions. | Ordinal, rater-dependent, and difficult to standardize across many rapid intra-op conditions. |
| **TETRAS-style and Fahn–Tolosa–Marín-style task families** | Established clinical tremor assessment frameworks. Relevant domains include postural/kinetic tremor, drawing, writing, and functional disability. | Provides clinical language for what the app is measuring: action tremor, writing/drawing impairment, and functional effect. | Full scales are not optimized for rapid intra-op repeated testing; individual scores can be coarse. Licensing/copyright should be considered before reproducing scale content. |
| **Visual spiral rating / free spiral drawing** | Longstanding, familiar tremor task with strong face validity. | Fast bedside kinetic tremor screen before/after stimulation. | Subjective if visually rated; brief drawing is only one slice of function; inter-rater variability. |
| **Digital spiral/stylus analysis** | Best-supported digital tablet/stylus task family in the review. Common features include path deviation, residual error, timing, pen lifts, path smoothness, and spectral features. | Good first quantitative app endpoint because clinicians already understand spirals and raw traces are easy to review. | Direct evidence for an iPad-specific awake-DBS workflow remains limited; outputs should be interpreted as standardized task metrics. |
| **Handwriting or glyph copying** | Clinically meaningful because writing disability is common and familiar to patients and clinicians. | Short intra-op glyph or handwriting sample can provide functional context alongside spiral score. | Language/content dependence; learning/fatigue effects; digital ET validation is more heterogeneous than spiral analysis. |
| **Instrumented accelerometry / wearables** | Objective motion capture with good temporal and spectral precision; relevant to tremor quantification and stimulation-response assessment. | Can quantify postural/action tremor and may detect changes not obvious visually. | Requires additional hardware, attachment, setup, and OR integration; not a drop-in replacement for tablet tasks. |
| **Side-effect checklist** | Clinically essential rather than a tremor-severity biomarker. | Documents therapeutic window: tremor benefit must be interpreted with paresthesia, dysarthria, ataxia/dysmetria, capsular motor pulling, visual symptoms, swallowing concerns, dizziness/nausea, and other effects. | Needs speed and simplicity; should not become a burdensome formal adverse-event form during surgery. |

## Promising but investigational app tasks

| Proposed task | Why it is attractive | Validation status for ET DBS |
|---|---|---|
| **Guided Archimedes spiral tracing** | Fixed geometry, familiar clinical task, easy automated scoring. Metrics: RMS radial error, 95th percentile error, completion time, path-length ratio, boundary exits, tremor-band residual power. | Closest to established spiral literature; reasonable core task for the prototype, but app-specific intra-op validation is still needed. |
| **Curved tunnel/path tracing** | Directly measures constrained path-following and yields intuitive percent-inside-corridor score. Difficulty can be tuned by corridor width and path shape. | Investigational for ET/DBS. Useful after core spiral workflow is stable. |
| **Straight-line tracing** | Very fast directionally constrained movement task. | Reasonable adjacent evidence and bedside plausibility, but limited ET-specific digital validation. |
| **Dot approximation / target dwell** | Measures endpoint control, dysmetria, and ability to stabilize at a target. | Promising and OR-feasible, but should be treated as investigational until validated. |
| **Fitts-style target acquisition** | Quantifies speed-accuracy tradeoff under graded difficulty. | Research extension; not a first-line intra-op endpoint. |

## What the current prototype should claim

Appropriate claims:

- Records timestamped intraoperative spiral trials.
- Computes transparent, task-specific spiral metrics.
- Captures crude clinician-entered side-effect scores and notes.
- Exports raw data and derived metrics for research analysis.
- Supports clinician review of tremor task performance across case chronology.

Claims to avoid:

- Diagnoses essential tremor.
- Selects DBS lead position.
- Selects stimulation contact or amplitude.
- Determines therapeutic window automatically.
- Replaces clinician assessment.
- Provides validated clinical outcome prediction.

## Recommended data captured per trial

Each saved trial should include:

- timestamp;
- trial number;
- phase, such as pre-lead, lead inserted/no stim, stim on, stim off, or other;
- hand tested;
- optional lead side;
- optional free-text stimulation/condition note;
- raw stylus samples: x, y, timestamp, pressure/force if available, stylus orientation when available;
- app/device/stylus metadata when feasible;
- spiral metrics: percent inside corridor, RMS radial error, 95th percentile error, boundary exits, completion time, stroke count, path efficiency, peak frequency estimate, quality label;
- side-effect scores: paresthesia, dysarthria, ataxia/dysmetria, motor pulling/capsular effect, other;
- free-text clinician note;
- validity/QC flags.

## Validation path

Before clinical deployment, the app should be validated in stages:

1. **Technical verification:** deterministic scoring, timestamp monotonicity, export integrity, replay reproducibility.
2. **Bench testing:** simulated or robotic traces with known amplitude/frequency to confirm score accuracy.
3. **Healthy volunteer usability:** task completion, training burden, screen layout, and failure modes.
4. **ET clinic validation:** compare app metrics with accepted tremor scales and repeatability measures.
5. **Awake DBS feasibility study:** time per trial, completion rate, invalid-trial rate, side-effect capture, and sensitivity to stimulation changes.
6. **Prospective outcome validation:** relationship between intra-op app measures and post-op tremor improvement, programming efficiency, and side-effect burden.

## Design implications for this repository

The current repository should prioritize a narrow, transparent, research-first workflow:

- guided spiral tracing;
- full-screen drawing mode;
- crude side-effect capture;
- timestamped trial saving;
- raw JSON export;
- baseline-versus-current comparison as the next major feature;
- no autonomous clinical recommendation.

That scope is intentionally conservative: it captures the best-supported digital task family while leaving more experimental tasks for later validation.
