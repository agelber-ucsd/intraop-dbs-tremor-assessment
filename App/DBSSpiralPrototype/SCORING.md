# Spiral scoring notes

The app records raw stylus/touch samples in a canonical 1000 x 1000 coordinate space. This lets the same drawing be displayed in the compact screen and the full-screen drawing mode without changing the stored trace.

The score is computed against an ideal Archimedes spiral using:

- sample count
- percent of samples inside the corridor
- mean absolute radial error
- RMS radial error
- 95th percentile absolute error
- maximum absolute error
- boundary exits
- completion time
- stroke count
- path length
- ideal path length
- path efficiency
- estimated peak residual frequency
- approximate residual power from 2–12 Hz
- quality label and quality notes

The quick effects fields are clinician-entered and optional:

- blank = not assessed / not entered
- 0 = absent
- 1 = mild
- 2 = moderate
- 3 = severe

Each saved trial includes timestamp, phase, hand tested, optional lead side, optional condition note, optional clinician note, side-effect scores, raw samples, automated score, corridor width, spiral turns, drawing coordinate space, and scoring canvas size.
