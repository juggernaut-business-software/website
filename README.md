# Juggernaut — website

A single-page, dependency-free website for Juggernaut, built from `content.md`
and the artwork in `assets/img`.

## Structure

```
index.html                  the page (hero, overview, capabilities, contact)
styles.css                  all styling and design tokens
script.js                   contact modal + reveal-on-scroll
content.md                  source copy
assets/img/                 character artwork (.webp, the only format kept)
tools/convert-to-webp.sh    regenerates the .webp files from the source artwork
docs/requirements/          the original brief
```

## Design notes

- **Background** is pure white (`--white`), including the sticky header (a
  translucent white with a blur).
- **Headings** use a friendly green (`--green: #0f7a63`) in **Poppins**, a
  clear sans. Blue (`--blue: #1d66d0`) is used for eyebrows and links.
- **Body text** uses **Lora**, a bookish serif, in the muted ink `--muted`.
- Both webfonts load from Google Fonts with robust system fallbacks, so the
  page still reads well offline.
- **Contact button** at the end of the page carries the 👋 emoji and opens a
  native `<dialog>` modal with Call, WhatsApp, Signal, Telegram and Email.
- **Artwork** ships as opaque WebP files with white backgrounds, so images sit
  directly on white surfaces (`object-fit: contain`, white media areas) rather
  than on tinted panels, which would reveal a visible white box.

## Images

The page loads the **WebP** files, and WebP is now the only image format left in
`assets/img`: the PNG originals and the JPEGs the site used to ship were deleted
once the WebP versions were verified.

```
assets/img/                .webp web versions (the only format kept)
```

`juggernaut_judge.jpeg` and `juggernaut_counting_money.jpg` arrived as JPEGs
with no PNG original, so those two were converted from the JPEGs directly.

Both arrived **arithmetic-coded** — `SOF9` plus a `DAC` table instead of the
usual `SOF0`/`DHT` — which browsers refuse to render (Safari reports "image
corrupt or truncated"). They were decoded with `sips -s format png` (macOS
ImageIO reads arithmetic coding; **ffmpeg does not**) and re-encoded, so both
are now baseline images. Arithmetic-coded files look perfectly ordinary to
`file(1)` and `sips`, so check new artwork before shipping it — `ffprobe` fails
on arithmetic coding with "No JPEG data found in image":

```sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,pix_fmt -of default=nw=1 \
  assets/img/<artwork>
```

Converting cut the artwork from 23.5 MB of source files (21.6 MB of PNGs plus
the 1.9 MB of JPEGs) to 1.2 MB — a 95% reduction — with no change to pixel
dimensions, and shaved ~35% off the JPEGs the page used to load (1.9 MB ->
1.2 MB). Two details matter:

- **Flattened onto white.** WebP is able to carry alpha, but the artwork is
  drawn on opaque white and a few files carry genuinely transparent corners, so
  every image is still composited onto a white canvas. That keeps the rendering
  identical to the JPEGs — and keeps the page's images on white surfaces: a
  white-background image would show a faint off-white rectangle against any
  tinted panel.
- **Sharp chroma.** `cwebp -sharp_yuv` keeps the coloured linework crisp rather
  than letting chroma bleed across edges.

After adding new artwork, regenerate the WebP files:

```sh
sh tools/convert-to-webp.sh
```

It needs `ffmpeg` (`brew install ffmpeg`) to flatten and `cwebp`
(`brew install webp`) to encode — Homebrew's ffmpeg ships without `libwebp`, so
`ffmpeg -c:v libwebp` is not available here. It is safe to re-run: a PNG is the
preferred source, and a JPEG is only converted when it has no PNG sibling.

On this tree a plain re-run converts nothing — it prints `converted 0 image(s)`
— because the PNGs it was written against are no longer in the working tree.
They are still in the commit that deleted them, so any single WebP can be
rebuilt from history if it is ever lost:

```sh
git show <deleting-commit>^:assets/img/<artwork>.png > assets/img/<artwork>.png
sh tools/convert-to-webp.sh
rm assets/img/<artwork>.png          # WebP stays the only format kept
```

Quality defaults to `-q 85`, which measures 43-50 dB PSNR against the source
for sixteen of the seventeen files — about a decibel under the JPEG the page
used to load — and 32 dB for `jaggurnaut_playful`. That outlier is not a
quality setting: it is the hardest file in the set (even its JPEG sibling was
the weakest of the fifteen at 33.7 dB), and it loses detail to VP8's
half-resolution chroma rather than to the quantiser, so q90 earns it 0.05 dB
while a global q88 costs 18% more bytes for 0.03 dB. Override the quality with
`WEBP_QUALITY=90 sh tools/convert-to-webp.sh` if that ever needs revisiting.

If a social or chat preview ever renders without an image, `og:image` /
`twitter:image` pointing at a `.webp` is the first thing to check: WebP is
widely accepted by modern scrapers, but a few still expect JPEG or PNG.

## Contact details used

| Channel  | Link                                    |
| -------- | --------------------------------------- |
| Call     | `tel:+918428050777`                     |
| WhatsApp | `https://wa.me/918428050777`            |
| Signal   | `https://signal.me/#p/+918428050777`    |
| Telegram | `https://t.me/+918428050777`            |
| Email    | `mailto:hello@numerical.works`          |

## SEO

On-page basics are in place in `index.html`:

- A `<title>` (50 chars) and meta `description` (154 chars) that cover the
  product, not just the brand name.
- `robots` with `max-image-preview:large`, so search engines may show full-size
  artwork in results.
- Open Graph and Twitter card tags, including image type, dimensions and alt
  text, so shared links render a proper preview.
- JSON-LD (`Organization` + `WebSite` + `SoftwareApplication`) describing the
  product, its capabilities and its contact channels.
- A clean heading outline: one `<h1>`, one `<h2>` per section, one `<h3>` per
  capability, with no skipped levels.
- Core Web Vitals: intrinsic `width`/`height` on every image (no layout shift),
  `fetchpriority="high"` on the hero image (the LCP element), and
  `loading="lazy" decoding="async"` on everything below the fold.
- Descriptive internal anchor text and per-image `alt` text; only genuinely
  decorative images (the header mark, the contact illustration) use `alt=""`.

### Site URL

The production URL `https://juggernaut.numerical.works/` is baked into these
places, so update all of them if the site ever moves:

| File | Where |
| --- | --- |
| `index.html` | `<link rel="canonical">`, `og:url`, `og:image`, `twitter:image`, and every `url`/`@id` in the JSON-LD |
| `sitemap.xml` | `<loc>` |
| `robots.txt` | `Sitemap:` |

`og:image` and `twitter:image` are absolute URLs deliberately: most social
scrapers will not resolve a relative image path, so a relative one silently
produces a preview with no image.

`robots.txt` and `sitemap.xml` must be served from the deploy root — the same
directory as `index.html` — for crawlers to find them.

### Optional, still open

- `offers` on the `SoftwareApplication` JSON-LD would unlock Google's
  software-app rich result, but it requires real prices, so none are invented.
- A small square favicon would beat the current 976x1099 WebP used as
  `rel="icon"`.
- Verify ownership in Google Search Console and submit
  `https://juggernaut.numerical.works/sitemap.xml` — that is an account action,
  not something the markup can do.

## Previewing

No build step. Open `index.html` directly, or serve the folder:

```sh
python3 -m http.server 8000
# then visit http://localhost:8000
```

## Accessibility

Skip link, keyboard-closable modal (native dialog handles focus trapping),
`prefers-reduced-motion` support, focus-visible outlines, and plain
`tel:`/`mailto:` links in the footer so contact details still work without
JavaScript.
