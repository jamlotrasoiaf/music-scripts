#!/bin/sh

# Usage: ./combine_stems.sh path/to/no_vocals.wav path/to/vocals.wav [output.wav]

no_vocals="$1"
vocals="$2"
output="${3:-combined.wav}"  # Default to combined.wav if not specified

# --- Check args ---
if [[ ! -f "$no_vocals" || ! -f "$vocals" ]]; then
  echo "Usage: $0 <no_vocals.wav> <vocals.wav> [output.wav]"
  echo "⚠️ Make sure both input WAV files exist"
  exit 1
fi

# --- Combine with compression ---
# -M = mix and pad shorter file
# compand = dynamic range compression to balance loudness
# gain -n = normalize to 0dB max
sox -M "$no_vocals" "$vocals" "$output" \
  compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 gain -n

echo "✅ Mixed and balanced: $output"
