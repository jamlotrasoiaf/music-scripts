#!/bin/bash
# needs sox and keyfinder-cli

input="$1"
if [[ -z "$input" ]]; then
  echo "Usage: $0 <audiofile.wav>"
  exit 1
fi

# Get the raw key directly
orig_key=$(keyfinder-cli "$input" | tr -d '\r')

# Mapping from minor to relative major
declare -A minor_to_major=(
  ["Abm"]="B" ["Am"]="C" ["A#m"]="C#" ["Bbm"]="Db" ["Bm"]="D"
  ["Cm"]="Eb" ["C#m"]="E" ["Dbm"]="E" ["Dm"]="F" ["D#m"]="F#"
  ["Ebm"]="Gb" ["Em"]="G" ["Fm"]="Ab" ["F#m"]="A" ["Gbm"]="A"
  ["Gm"]="Bb" ["G#m"]="B"
)

# Map major keys to themselves, and fix enharmonic variants
declare -A toD=(
  ["C"]=2 ["C#"]=1 ["Db"]=1 ["D"]=0 ["D#"]=-1 ["Eb"]=-1 ["E"]=-2
  ["F"]=-3 ["F#"]=-4 ["Gb"]=-4 ["G"]=5 ["G#"]=4 ["Ab"]=4
  ["A"]=7 ["A#"]=6 ["Bb"]=6 ["B"]=3
)

# Normalize key
if [[ "$orig_key" == *m ]]; then
  rel_major="${minor_to_major[$orig_key]}"
  if [[ -z "$rel_major" ]]; then
    echo "❌ Unrecognized minor key: $orig_key"
    exit 2
  fi
  norm_key="$rel_major"
  echo "🎵 Detected minor key: $orig_key → Relative major: $norm_key"
else
  norm_key="$orig_key"
  echo "🎵 Detected major key: $norm_key"
fi

# Find pitch shift
shift_val=${toD[$norm_key]}
if [[ -z "$shift_val" ]]; then
  echo "❌ Key '$norm_key' not recognized in shift map."
  exit 3
fi

# Apply shift with sox
echo "📦 Shifting pitch by $shift_val semitones to D Major..."
output="${input%.wav}_Dmaj.wav"
sox "$input" "$output" pitch $((shift_val * 100))
echo "✅ Saved as: $output"
