#!/bin/sh
#
# Convert every PNG in assets/img/ to a high-quality, web-friendly JPEG.
#
#   sh tools/convert-to-jpeg.sh
#
# The PNG originals are left untouched. Each PNG gains a sibling .jpg with the
# same base name and the same pixel dimensions.
#
# The artwork is drawn on opaque white, but some files carry transparent
# corners, so every image is composited onto a white canvas first. Skipping
# that step makes JPEG render those transparent areas as black.
#
# Requires ffmpeg (brew install ffmpeg). Override the quality with
# JPEG_QUALITY (ffmpeg's -q:v scale, 2 = best, 31 = worst):
#
#   JPEG_QUALITY=2 sh tools/convert-to-jpeg.sh
#
set -eu

dir="$(dirname "$0")/../assets/img"
quality="${JPEG_QUALITY:-4}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "error: ffmpeg not found. Install it with: brew install ffmpeg" >&2
  exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "error: ffprobe not found (it ships with ffmpeg)." >&2
  exit 1
fi

count=0
for png in "$dir"/*.png; do
  [ -e "$png" ] || continue

  dims=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0 "$png")
  width=${dims%,*}
  height=${dims#*,}

  out=${png%.png}.jpg

  ffmpeg -y -hide_banner -loglevel error \
    -f lavfi -i "color=c=white:s=${width}x${height}" \
    -i "$png" \
    -filter_complex "[0:v]format=rgb24[bg];[1:v]format=rgba[fg];[bg][fg]overlay=format=rgb:shortest=1,format=rgb24[out]" \
    -map "[out]" \
    -frames:v 1 \
    -q:v "$quality" \
    -map_metadata -1 \
    "$out"

  before=$(wc -c < "$png" | tr -d ' ')
  after=$(wc -c < "$out" | tr -d ' ')
  printf '  %-40s %6s KB -> %6s KB\n' \
    "$(basename "$png")" "$((before / 1024))" "$((after / 1024))"
  count=$((count + 1))
done

echo "converted $count image(s) at -q:v $quality"
