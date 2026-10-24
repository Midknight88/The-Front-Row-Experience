# The Front Row Experience

A phone web app that drives K-pop light sticks over Bluetooth, all in sync, the way a concert venue does. Live site: https://midknight88.github.io/The-Front-Row-Experience/

Open it in Chrome on Android (or the Bluefy browser on iPhone). Everything is in `index.html`.

## Shows

Shows live in `shows/`. The app loads every file listed in `shows/index.json`.

A show is JSON:

```json
{
  "format": "front-row-show/1",
  "id": "unique-id",
  "title": "Song title",
  "artist": "Artist",
  "bpm": 120,
  "tempo": "show",
  "duration": 196,
  "draft": true,
  "notes": "One line on the concept",
  "cues": [
    {"t": 0, "section": "Intro", "fx": "Pulse", "colors": ["#B8860B"], "bright": 0.6, "spread": 0.3, "bpm": 120}
  ]
}
```

- `t`: when the cue starts, in seconds from the first beat of the song (or `"m:ss.s"`).
- `fx`: Solid, Pulse, Strobe, Rainbow, Wave, Chase, Sparkle or Off.
- `colors`: up to 3; the first is the main color. Wave, Chase and Sparkle use the rest.
- `bright`: 0 to 1. `spread`: 0 to 1, how much the effect is staggered across sticks.
- `bpm` on a cue: a tempo change starting there.
- `tempo`: `"show"` uses the show's BPM; `"listen"` follows the microphone's beat detection.
- `youtube`: `{"id": "<video id>", "offset": <seconds into the video where the song starts>}`, so the show plays its own video in sync.
- `draft: true` means the section times were planned without hearing the song. Fix them in the app with **Mark next section** while the song plays.

### Making a show from a YouTube link

Send Claude `NewShow: <YouTube link>`, plus any notes such as keeping a storyline intro dark (the app's **Copy request for Claude** button builds the message). Claude identifies the song from the video, plans the show around the song's sections and concept, saves it as `shows/<artist>-<song>.json` with that video's `youtube.id`, lists it in `shows/index.json` and pushes. When that video is loaded in the app, its show is picked automatically.

### Making your edits the Claude version

In the app, edit a show and tap **Send to Claude**. It copies a message with the show code, including the original show's `id`. Claude saves it over `shows/<file>.json` for that `id`, keeping the cues, colors and timing exactly as sent, sets `draft` to false if the timing was marked, and pushes. On the next reload the app sees the personal copy matches the Claude version and removes the copy.

## Music sources

- **YouTube**: the song plays in YouTube's embedded player inside the app, and the lights follow its exact position.
- **Song file**: a file from the phone, analyzed for tempo and played in sync.
- **Other app**: tap Start on the first beat.

## Light stick protocols

Built-in profiles are in `BUILTIN_PROFILES` in `index.html`. **+ Bluetooth** lists every known stick type in one chooser and detects the type by name (then by service); sticks that share a service get a Type switch in their row. Templates use hex bytes plus `{r} {g} {b} {w}`, and `{sumN}` for a checksum (sum of bytes N..here, low 8 bits).

- **P1Harmony** (Fanlight app, unencrypted): service `00010203-0405-0607-0809-0a0b0c0d1911`, characteristic `…0d2b19`, written with response. Ver.1: `01 01 0B 00 00 RR GG BB 00 00 SUM`; Ver.2: `01 FF 00 RR GG BB 00 00 SUM`; SUM = bytes from position 2 added up, low 8 bits. Sticks advertise as `P1H LIGHT STICK`. Confirmed on the real stick.
- **The Rose OLS Ver.2** (Fanlight app kr.co.fanlight.therose): same service, characteristic and command as P1Harmony Ver.2: `01 FF 00 RR GG BB WW SS SUM` (white and strobe left at 0). Advertises as `THE ROSE OLS`. Confirmed on the real stick.
- **MONSTA X V3** (Soundwave app, same Bluetooth code as Stray Kids V2): uses the Stray Kids command and key, confirmed on the real stick.
- **ATEEZ** (Eumhana LIGHTINY app, Nordic chip, unencrypted): sticks are recognized by advertised service `8ec91001-f315-4f60-9fb8-838830daea50`. Solid color on characteristic `8ec91002-…`: `01 00 00 RR GG BB 00 00` (effect 1 = stay; 2 strobe, 3 dimming, 4 fading, 5/6 dim up/down, last two bytes = time). A richer 20-byte command set exists on `8ec91004-…`. Confirmed on both the gold (Ver.2) and silver (Ver.1) sticks.
- **BTS Ver.4** (HYBE platform, Flutter app; decoded with Blutter + Capstone): LED channel service `0001fe01-0000-1000-8000-00805f9800c4`, characteristic `0001ff02-…9800c4`. Command `[effect, RR, GG, BB]`, effect 0 off, 1 on, 2 blink, 3 breath, 4 strobe; sent unencrypted (the app's `DEVICE_ENCRYPT_KEY` is used for other data). Other channels: fe02/ff04 library data, fe03/ff05 MAC, fe04/ff06 event id, fe06/ff13 OTA. Advertised name comes from HYBE's server (pattern like "SEVENTEEN LIGHT STICK VER3"); the app matches names starting "BTS" or the service, and **Show all nearby devices** is the fallback.
 The Stray Kids Light Stick V2 protocol: service and characteristic `0x0000`, 16-byte command `82 01 RR GG BB 00 00 00 00 00 FD 47 52 41 56 45`, AES-128-ECB encrypted, written with response about every 70 ms.
