#!/bin/sh
#
# Convert every PNG in assets/img/ to a high-quality, web-friendly WebP.
#
#   sh tools/convert-to-webp.sh
#
# The PNG originals are left untouched. Each PNG gains a sibling .webp with the
# same base name and the same pixel dimensions. JPEGs that have no PNG sibling
# (artwork that arrived already as JPEG) are converted too.
#
# The artwork is drawn on opaque white, but some files carry transparent
# corners, so every image is composited onto a white canvas first. WebP is able
# to carry alpha, but the page draws its images on white surfaces and JPEG had
# to flatten them anyway, so flattening keeps the rendering identical.
#
# Requires ffmpeg (brew install ffmpeg) to flatten, and cwebp
# (brew install webp) to encode. cwebp encodes because ffmpeg's Homebrew build
# ships without libwebp, so `ffmpeg -c:v libwebp` is not available here.
#
# Override the quality with WEBP_QUALITY (cwebp's -q scale, 0 = worst,
# 100 = best). At the default of 85, sixteen of the seventeen files measure
# 43-50 dB PSNR against the source they were encoded from, roughly a decibel
# under the JPEG this pipeline replaced. jaggurnaut_playful is the exception
# at 32 dB, and quality is not what ails it: q90 earns it 0.05 dB, because VP8
# keeps chroma at half resolution and that artwork is fine coloured linework
# on white, so its loss is subsampling, not the quantiser. Raising the default
# to q88 costs 18% more bytes for 0.03 dB overall, which is why 85 stands:
#
#   WEBP_QUALITY=80 sh tools/convert-to-webp.sh
#
set -eu

dir="$(dirname "$0")/../assets/img"
quality="${WEBP_QUALITY:-85}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "error: ffmpeg not found. Install it with: brew install ffmpeg" >&2
  exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "error: ffprobe not found (it ships with ffmpeg)." >&2
  exit 1
fi

if ! command -v cwebp >/dev/null 2>&1; then
  echo "error: cwebp not found. Install it with: brew install webp" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

count=0
for src in "$dir"/*.png "$dir"/*.jpg "$dir"/*.jpeg; do
  [ -e "$src" ] || continue

  base=$(basename "$src")
  stem=${base%.*}

  # A PNG is the source of truth. A JPEG is only converted when it has no PNG
  # sibling, so the higher-quality original is never bypassed.
  case $src in
    *.png) ;;
    *) [ -e "$dir/$stem.png" ] && continue ;;
  esac

  dims=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0 "$src")
  width=${dims%,*}
  height=${dims#*,}

  ffmpeg -y -hide_banner -loglevel error \
    -f lavfi -i "color=c=white:s=${width}x${height}" \
    -i "$src" \
    -filter_complex "[0:v]format=rgb24[bg];[1:v]format=rgba[fg];[bg][fg]overlay=format=rgb:shortest=1,format=rgb24[out]" \
    -map "[out]" \
    -frames:v 1 \
    "$tmpdir/flat.png"

  out="$dir/$stem.webp"

  # -m 6 is the slowest, densest search; -sharp_yuv keeps the coloured linework
  # crisp; -metadata none drops EXIF/ICC blocks the artwork does not need.
  cwebp -quiet \
    -q "$quality" \
    -m 6 \
    -sharp_yuv \
    -metadata none \
    "$tmpdir/flat.png" -o "$out"

  before=$(wc -c < "$src" | tr -d ' ')
  after=$(wc -c < "$out" | tr -d ' ')
  printf '  %-40s %6s KB -> %6s KB\n' \
    "$base" "$((before / 1024))" "$((after / 1024))"
  count=$((count + 1))
done

echo "converted $count image(s) at -q $quality"
