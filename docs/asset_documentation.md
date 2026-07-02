# Asset Specifications and Scaling Documentation

This document lists the native pixel sizes, target render sizes, scale factors, and positions for all assets, UI elements, characters, and environments used in the game.

## 1. Environments

The game operates on a viewport resolution of 1152x648 (16:9 ratio). Background scale factors are configured to fit the viewport height of 648.

| Environment / Asset Name | Native File Size | Screen Height target | Render Scale Factor | Total Rendered Dimensions | Screen Position / Limits |
|---|---|---|---|---|---|
| `bedroom (bottom layer)` | 700x360 | 648 | 1.8 | 1260x648 | Center: (630, 324). Camera right limit: 1260. |
| `bedroom (upper layer)` | 700x360 | 648 | 1.8 | 1260x648 | Center: (630, 324) |
| `640x360 all sides class (bottom)`| 640x360 | 648 | 1.8 | 1152x648 | Center: (576, 324). Camera right limit: 1152. |
| `640x360 all sides class (upper)` | 640x360 | 648 | 1.8 | 1152x648 | Center: (576, 324) |
| `HALLWAY3` (corridor) | 1536x208 | 648 | 3.115 | 4784x648 (Width scaled) | Center: (600, 324). Camera right limit: 1200. |

## 2. Character Sprites

Exploration and combat sprites have different native sizes and render scales.

| Sprite Name | Native File Size | Purpose | Render Scale Factor | Rendered Dimensions | Alignment / Facing |
|---|---|---|---|---|---|
| `3_4test.png` | 258x258 | Exploration Idle | 0.75 | 193.5x193.5 | Centered. Faces right by default. |
| `walk falsya ver-Sheet` | 512x128 (4 frames) | Exploration Walk | 1.5 (per 128x128 frame)| 192x192 | Centered. Faces left by default. |
| `DreamHilbertSideways.png` | 128x128 | Combat Player Stance| 0.75 | 96x96 | Centered. Faces right. |
| `Monster1.png` | 256x256 | Combat Sentry / Monster | 0.375 | 96x96 | Centered. Faces left. |
| `Monster2.png` | 256x256 | Combat Sentry / Monster | 0.375 | 96x96 | Centered. Faces left. |
| `PACKLEADER.png` | 256x256 | Combat Boss / Pack Leader| 0.5 | 128x128 | Centered. Faces left. |
| `n.n..png` | 2048x2048 | Dialogue Portrait | Aspect centered | Unbounded VN portrait | Aligned right. |
| `character3.png` | 258x258 | Dialogue Portrait | Aspect centered | Unbounded VN portrait | Aligned left. |

## 3. Combat UI Textures

Combat UI textures are loaded dynamically. The target dimensions are forced programmatically to preserve crisp retro pixel-art presentation.

| Asset Name | Native File Size | Intended Design Size | Applied Scale Factor | Final Render Size | Screen Position / Anchor |
|---|---|---|---|---|---|
| `energy_orb_48x48.png` | 161x158 | 48x48 | 0.30 | 48x48 | Centered at (122, 512) |
| `prog_bar_frame_16x6.png` | 207x61 | 16x6 (unit block) | 0.08 | 160x12 (stretched) | Progress line tracking |
| `green_fill_8x4_full.png` | 96x22 | 8x4 (unit block) | 0.08 | 156x8 (stretched) | Inside progress bar frame |
| `blue_full_8x4_full.png` | 94x20 | 8x4 (unit block) | 0.08 | 156x4 (stretched) | Block Shield highlight |
| `end_turn_btn_96x32.png` | 240x114 | 96x32 | 0.40 | 96x32 | Hand action panel |
| `shift_button_80x32.png` | 183x114 | 80x32 | 0.44 | 80x32 | Hand action panel |
| `reroll_button_32x32.png` | 124x114 | 32x32 | 0.26 | 32x32 | Hand action panel |
| `attack_indicator_16x16.png`| 95x95 | 16x16 | 0.17 | 16x16 | Next to intent label |
| `defend_indicator_16x16.png`| 95x95 | 16x16 | 0.17 | 16x16 | Next to intent label |
| `special_indicator_16x16.png`| 95x95 | 16x16 | 0.17 | 16x16 | Next to intent label |
| `targeting_arrow_32x32.png`| 158x158 | 32x32 | 0.20 | 32x32 | Centered above active enemy |
| `card_pile_icon_32x32.png` | 155x144 | 32x32 | 0.21 | 24x24 (custom scaled) | Left border of booklet button |
| `hud_stats_box_160x50.png` | 363x159 | 160x50 | 0.44 | 160x50 | Top-left status overlay |
| `shift_gauge_bar_X_120x16.png`| 388x113 | 120x16 | 0.31 | 120x16 | Above shift button |
| `turn_banner_400x80.png` | 1207x256 | 400x80 | 0.33 | 400x80 | Centered behind screen announcements|
| `victory_banner_240x48.png` | 583x211 | 240x48 | 0.41 | 240x48 | Centered behind screen victory text |
| `defeat_banner_240x48.png` | 583x211 | 240x48 | 0.41 | 240x48 | Centered behind screen defeat text |

## 4. Audio Streams

All audio streams loop by default if designated as ambient or music.

| Audio Path | Stream Type | File Format | Loop Logic | Purpose |
|---|---|---|---|---|
| `res://Assets/OST/Title Screen - OST 000.mp3` | Music | MP3 | Loops | Title screen background |
| `res://Assets/OST/Home - OST 001.mp3` | Music | MP3 | Loops | Bedroom scene background |
| `res://Assets/OST/Dream World - OST 002.mp3` | Music | MP3 | Loops | Combat battle music |
| `res://Assets/OST/College - OST 003.mp3` | Music | MP3 | Loops | School corridor and class background |
| `res://Assets/Sound Effects/World, Ambient, and UI/amb_bird_chirp_bedroom_ambience_please loop.mp3` | Ambience | MP3 | Loops | Bedroom birds chirping |
| `res://Assets/Sound Effects/World, Ambient, and UI/amb_college_hallway.mp3` | Ambience | MP3 | Loops | Student whispers background |
| `res://Assets/Sound Effects/World, Ambient, and UI/amb_classroom.mp3` | Ambience | MP3 | Loops | Classroom background hum |
| `res://Assets/Sound Effects/World, Ambient, and UI/sfx_clock_ticking_please loop.mp3` | SFX | MP3 | Loops | Persistent ticking clock sound |
| `res://Assets/Sound Effects/World, Ambient, and UI/sfx_alarm_buzz (just use once please, do not loop).mp3` | SFX | MP3 | Single Play | Alarm buzz event |
