# Juggernaut — website

A single-page, dependency-free website for Juggernaut, built from `content.md`
and the artwork in `assets/img`.

## Structure

```
index.html                  the page (hero, overview, capabilities, contact)
styles.css                  all styling and design tokens
script.js                   contact modal + reveal-on-scroll
content.md                  source copy
assets/img/                 character artwork
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

## Contact details used

| Channel  | Link                                    |
| -------- | --------------------------------------- |
| Call     | `tel:+918428050777`                     |
| WhatsApp | `https://wa.me/918428050777`            |
| Signal   | `https://signal.me/#p/+918428050777`    |
| Telegram | `https://t.me/+918428050777`            |
| Email    | `mailto:hello@numerical.works`          |

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
