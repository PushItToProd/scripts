#!/usr/bin/env bash
# A quick and dirty script for making GIFs with ffmpeg.
set -euo pipefail

input=
start=
duration=
fps=12
width=480
scale_flags=lanczos
stats_mode=diff
format=gif
dither=bayer:bayer_scale=5:diff_mode=rectangle
output=

usage() {
  cat <<EOF
usage: $0 [options]

options:
    -i input file
    -s start time
    -d duration from start
    -fps fps (optional, default: $fps)
    -w width (optional, default: $width)
    -fmt output format (optional, default: $format)
    -stats_mode stats mode (optional, default $stats_mode)
    -dither dithering mode (optional, default $dither)
    -o output file (optional, default: [filename].$format)
    -h print this message
EOF
  exit 1
}

require_argument() {
  if [[ -z "$1" ]]; then
    echo "missing required argument: $2" >&2
    usage
    exit 1
  fi
}

usage_error() {
  echo "missing required argument: $1" >&2
  usage
  exit 1
}

parse() {
  while (( "$#" )); do
    flag="$1"
    shift
    case "$flag" in
      -i)
        input="$1"
        ;;
      -s)
        start="$1"
        ;;
      -d)
        duration="$1"
        ;;
      -fps)
        fps="$1"
        ;;
      -w)
        width="$1"
        ;;
      -o)
        output="$1"
        ;;
      -fmt)
        format="$1"
        ;;
      -stats_mode)
        stats_mode="$1"
        ;;
      -dither)
        dither="$1"
        ;;
      -h)
        usage
        exit
        ;;
      *)
        echo "unrecognized argument: $1" >&2
        exit 1
        ;;
    esac
    shift
  done
  require_argument "$input" -i
  require_argument "$start" -s
  require_argument "$duration" -d
  echo "input = $input"
  echo "start = $start"
  echo "duration = $duration"
  echo "fps = $fps"
  echo "width = $width"
  echo "output = $output"
  echo "format = $format"
  echo "stats_mode = $stats_mode"
  echo "dither = $dither"
  if [[ -z "$output" ]]; then
    output="${input}.${format}"
  fi
}

make_gif() {
  filter="
    [0:v] fps=${fps},
          scale=w=${width}:h=-1:flags=${scale_flags},
          split
          [a][b];
    [a] palettegen=stats_mode=${stats_mode} [p];
    [b][p] paletteuse=dither=${dither}
  "

  ffmpeg -ss "$start" -t "$duration" -i "$input" \
    -filter_complex "$filter" \
    "$output"
}

main() {
  parse "$@"
  make_gif
}
[[ "${#BASH_SOURCE[@]}" -eq 1 ]] && main "$@"
