#!/bin/bash

input="$1"
target_key="$2"

if [[ -z "$input" || -z "$target_key" ]]; then
  echo "Usage: $0 <audiofile.wav|.mp3> <TARGET_KEY (e.g., D, F#, Bb, Am)>"
  exit 1
fi

# Handle MP3 input
ext="${input##*.}"
basename="${input%.*}"
if [[ "$ext" == "mp3" ]]; then
  tmp_wav="${basename}_tmp.wav"
  echo "🎧 Converting MP3 to WAV..."
  ffmpeg -y -i "$input" "$tmp_wav" >/dev/null 2>&1
  input="$tmp_wav"
fi

# Get original key (can be Am, G#m, etc.)
orig_key=$(keyfinder-cli "$input" | tr -d '\r')

# Semitone mapping (major + minor)
declare -A semitones=(
  ["C"]=0 ["C#"]=1 ["Db"]=1 ["D"]=2 ["D#"]=3 ["Eb"]=3 ["E"]=4
  ["F"]=5 ["F#"]=6 ["Gb"]=6 ["G"]=7 ["G#"]=8 ["Ab"]=8
  ["A"]=9 ["A#"]=10 ["Bb"]=10 ["B"]=11
  ["Cm"]=0 ["C#m"]=1 ["Dbm"]=1 ["Dm"]=2 ["D#m"]=3 ["Ebm"]=3 ["Em"]=4
  ["Fm"]=5 ["F#m"]=6 ["Gbm"]=6 ["Gm"]=7 ["G#m"]=8 ["Abm"]=8
  ["Am"]=9 ["A#m"]=10 ["Bbm"]=10 ["Bm"]=11
)

from=${semitones[$orig_key]}
to=${semitones[$target_key]}

if [[ -z "$from" || -z "$to" ]]; then
  echo "❌ Invalid key(s): detected='$orig_key' or target='$target_key'"
  [[ "$tmp_wav" ]] && rm "$tmp_wav"
  exit 2
fi

# Calculate smallest pitch shift (modulo 12)
shift_val=$((to - from))
if (( shift_val > 6 )); then shift_val=$((shift_val - 12)); fi
if (( shift_val < -6 )); then shift_val=$((shift_val + 12)); fi

echo "🎼 Detected key: $orig_key"
echo "🎯 Target key:   $target_key"
echo "🎚 Shifting pitch by $shift_val semitones..."

output="${basename}_to_${target_key}.wav"
sox "$input" "$output" pitch $((shift_val * 100))

[[ "$tmp_wav" ]] && rm "$tmp_wav"

echo "✅ Output saved as: $output"
