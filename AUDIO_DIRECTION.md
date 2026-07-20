# Audio Direction

The score is an original procedural chamber-dark-folk language: bowed-drone synthesis, modal plucked strings, breathy flute partials, frame-drum pulses, struck iron, and granular wind. Themes share a four-note Bell motif but vary meter, mode, density, and orchestration.

Music uses seamless stereo WAV loops at 44.1 kHz with conservative -3 dB peaks. Exploration cues have intensity stems where practical; combat crossfades on logical state. Effects are short original syntheses with randomized pitch selected deterministically from variants. Ambience is separately controlled from music and effects.

The canonical source is tools/audio_pipeline/generate_audio.py with seed 44117. It generates at least 12 cues and 100 effect/ambience files, normalizes peaks, checks duration/channel/rate, and writes manifest hashes. No downloaded samples or soundfonts are used.

