#!/bin/bash

input="$1"
target_key="$2"
shift_arg="$3"

if [[ -z "$input" || -z "$target_key" ]]; then
  echo "Usage: $0 <audiofile.wav|.mp3> <TARGET_KEY> [--shift N (semitones, e.g., -12, -6, +3)]"
  exit 1
fi

# Parse optional semitone shift
extra_shift=0
if [[ "$shift_arg" =~ ^--shift[=\ ]?([-+]?[0-9]+)$ ]]; then
  extra_shift="${BASH_REMATCH[1]}"
elif [[ -n "$shift_arg" ]]; then
  echo "❌ Invalid argument: $shift_arg"
  echo "Use: --shift ±N  (e.g., --shift -12 or --shift=6)"
  exit 2
fi

# Convert MP3 to WAV if needed
ext="${input##*.}"
basename="${input%.*}"
if [[ "$ext" == "mp3" ]]; then
  tmp_wav="${basename}_tmp.wav"
  echo "🎧 Converting MP3 to WAV..."
  ffmpeg -y -i "$input" "$tmp_wav" >/dev/null 2>&1
  input="$tmp_wav"
fi

# Get original key
orig_key=$(keyfinder-cli "$input" | tr -d '\r')

# Semitone mapping
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
  exit 3
fi

# Compute base shift and wrap
base_shift=$((to - from))
if (( base_shift > 6 )); then base_shift=$((base_shift - 12)); fi
if (( base_shift < -6 )); then base_shift=$((base_shift + 12)); fi

# Total pitch shift
total_shift=$((base_shift + extra_shift))

echo "🎼 Detected key: $orig_key"
echo "🎯 Target key:   $target_key"
echo "🎚 Extra shift:  $extra_shift semitones"
echo "🎛 Total shift:  $total_shift semitones"

output="${basename}_to_${target_key}"
[[ $extra_shift -ne 0 ]] && output="${output}_shift${extra_shift}"
output="${output}.wav"

sox "$input" "$output" pitch $((total_shift * 100))

[[ "$tmp_wav" ]] && rm "$tmp_wav"

echo "✅ Output saved as: $output"
