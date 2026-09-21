# Juggernaut — website

A single-page, dependency-free website for Juggernaut, built from `content.md`
and the artwork in `assets/img`.

## Structure

```
index.html                  the page (hero, overview, capabilities, contact)
styles.css                  all styling and design tokens
script.js                   contact modal + reveal-on-scroll
content.md                  source copy
assets/img/                 character artwork (.jpg used by the page, .png originals kept)
tools/convert-to-jpeg.sh    regenerates the .jpg files from the .png originals
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
- **Artwork** ships as opaque PNGs with white backgrounds, so images sit
  directly on white surfaces (`object-fit: contain`, white media areas) rather
  than on tinted panels, which would reveal a visible white box.

## Images

The page loads the **JPEG** files; the PNG originals are kept alongside them
and are not referenced by `index.html`.

```
assets/img/                .png originals (unused by the page)
                           .jpg web versions (used by index.html)
```

Converting cut the artwork from ~21 MB to ~1.7 MB (a ~92% reduction) with no
change to pixel dimensions. Two details matter:

- **Flattened onto white.** The artwork is drawn on opaque white, but a few
  files carry genuinely transparent corners. JPEG has no alpha channel, and
  ffmpeg's default behaviour leaves those areas black, so the conversion first
  composites each image onto a white canvas. This is also why the page keeps
  images on white surfaces: a JPEG of a white-background image would show a
  faint off-white rectangle against any tinted panel.
- **4:4:4 sampling.** ffmpeg encodes these as full-chroma JPEGs, so there is no
  chroma bleed around the coloured linework.

After adding new artwork, regenerate the JPEGs:

```sh
sh tools/convert-to-jpeg.sh
```

It needs `ffmpeg` (`brew install ffmpeg`) and is safe to re-run. Quality
defaults to `-q:v 4` (~90%, measured at 38–46 dB PSNR against the originals);
override it with `JPEG_QUALITY=2 sh tools/convert-to-jpeg.sh`.

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
- A small square favicon would beat the current 976x1099 JPEG used as
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
