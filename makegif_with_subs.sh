#!/usr/bin/env bash
# A quick and dirty script for making GIFs with subtitles using ffmpeg.
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
  -i           input file
  -s           start time
  -d           duration from start
  -fps         fps (optional, default: $fps)
  -w           width (optional, default: $width)
  -fmt         output format (optional, default: $format)
  -stats_mode  stats mode (optional, default $stats_mode)
  -dither      dithering mode (optional, default $dither)
  -o           output file (optional, default: [filename].$format)
  -h           print this message
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
        shift
        ;;
      -s)
        start="$1"
        shift
        ;;
      -d)
        duration="$1"
        shift
        ;;
      -fps)
        fps="$1"
        shift
        ;;
      -w)
        width="$1"
        shift
        ;;
      -o)
        output="$1"
        shift
        ;;
      -fmt)
        format="$1"
        shift
        ;;
      -stats_mode)
        stats_mode="$1"
        shift
        ;;
      -dither)
        dither="$1"
        shift
        ;;
      -h)
        usage
        exit
        ;;
      *)
        echo "unrecognized argument: $flag" >&2
        exit 1
        ;;
    esac
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

make_gif_with_subs() {
  tmp="$(mktemp -p . "tmpXXXXX.${input}")"
  # first we cut the video with subtitles
  ffmpeg -i "$input" \
         -ss "$start" \
         -filter_complex "subtitles='${input}'" \
         -t "$duration" \
         -y "$tmp"  # overwrite the temp file

  filter="
    [0:v] fps=${fps},
          scale=w=${width}:h=-1:flags=${scale_flags},
          subtitles='${tmp}',
          split
          [a][b];
    [a] palettegen=stats_mode=${stats_mode} [p];
    [b][p] paletteuse=dither=${dither}
  "

  # now we actually make the gif
  ffmpeg -i "$tmp" \
    -filter_complex "$filter" \
    "$output"

  rm "$tmp"
}

main() {
  parse "$@"
  make_gif_with_subs
}
[[ "${#BASH_SOURCE[@]}" -eq 1 ]] && main "$@"
