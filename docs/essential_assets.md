# Essential Pixel-Art Asset Requirements (Minimum Viable List)

This document provides a highly optimized, stripped-down list of core assets required for the game to function. It reduces the workload of the art team by eliminating unnecessary animations, using procedural solutions in Godot, cutting optional objects, and simplifying frame counts to the absolute minimum.

---

## 1. Technical Framework and Guidelines

- **Base Resolution**: 512 x 208 pixels for all gameplay backgrounds and cutscenes.
- **Godot Scaling**: Assets are scaled by 3.115x to fit the 1152 x 648 viewport. Nearest-neighbor filtering must be enabled in project settings.
- **Ground Floor Line**: Y = 166.
- **Procedural Outlines**: Interactive objects do not need hand-drawn frame animations for the hover jitter/pencil outline. Godot shaders will handle the outline outline and jitter effect programmatically.
- **Procedural UI**: Textboxes, health bars, charge gauges, button panels, and screen banners will be built inside Godot using procedural UI StyleBoxFlat elements and ColorRect controls. No custom drawing or textures are required for background panels, badges, or buttons.

---

## 2. Minimal Background List

Only 5 background assets are required. All exploration and combat share the same dimension and aspect ratio.

| Background Name | Dimensions | Scene / Area | Description | Urgency |
|---|---|---|---|---|
| `bedroom_bg` | 512 x 208 | Hilbert's Apartment (Tutorial) | Standard room layout. Features bed, desk, wardrobe positions. | Critical |
| `classroom_bg` | 512 x 208 | University Lecture Hall | Classroom rows, professor podium space, blackboard space. | Critical |
| `grassy_field_bg` | 512 x 208 | Dream World Battleground | Flat grassy floor line. Circular sky patterns, sun gear motif. | Critical |
| `hallway_bg` | 512 x 208 | University Corridor | Lockers, office doors, water fountain positions. | High |
| `burning_village_bg` | 512 x 208 | Dream World Village (Chapter 2) | Burning village silhouettes, smoke debris. | High |

---

## 3. Simplified Interactive Objects

All objects are static (1 frame only). Interactive hover outlines and highlights are handled in the engine.

| Object Name | Dimensions | Description | Urgency |
|---|---|---|---|
| `bed` | 96 x 64 | MESSY single bed. Player interact target. | Critical |
| `wardrobe` | 48 x 80 | Tall wooden cabinet. Player interact target. | Critical |
| `desk_apartment` | 64 x 48 | Study desk with papers. Player interact target. | Critical |
| `blackboard` | 120 x 60 | Classroom blackboard. Player interact target. | Critical |
| `locker` | 32 x 80 | University hallway locker. Player interact target. | High |

*Note: Optional aesthetic items (shower, toilet, kitchen counter, papers, window, guitar) are cut from the art pipeline. The backgrounds themselves contain static representations where needed.*

---

## 4. Minimal Character Sprite Sheets

NPC sprites are completely static (1 frame) to remove all character animation tasks except for the player character and combat enemies.

### Hilbert (Player Character)
- **Grid Dimensions**: 32 x 32 pixels per frame.
- **Total Frames**: 7 frames (reduced from 36 frames).

| Animation State | Frame Range | Loop | Description | Urgency |
|---|---|---|---|---|
| `Idle` | 0 - 1 (2 frames) | Yes | Subtle breathing stance. | Critical |
| `Walk` | 2 - 5 (4 frames) | Yes | Standard 4-frame walk cycle. | Critical |
| `Lying Down` | 6 (1 frame) | No | Static sleeping frame on bed. | Critical |

*Note: Reach, read, stress, and dissolve animations are cut. Code will handle transitions via canvas fading and simple screen shakes.*

### Non-Player Characters (NPCs)
- **Grid Dimensions**: 32 x 48 pixels.
- **Total Frames**: 1 frame per character (static sprite).

| NPC Name | Total Frames | Stance Description | Urgency |
|---|---|---|---|
| `Professor` | 1 frame | Standing, pointing slightly forward. | Critical |
| `Landlady` | 1 frame | Standing with hands crossed in front. | High |
| `Peer 1` | 1 frame | Sitting at a desk, looking forward. | High |
| `Peer 2` | 1 frame | Sitting at a desk, looking downward. | High |

---

## 5. Combat Golems and Enemies

Animation sequences are cut down to the absolute minimum required to convey action: 2 frames for idle, 2 frames for attack, 1 frame for hit/death.

### Monster Base (Standard Gear Golem)
- **Dimensions**: 96 x 96 pixels.
- **Total Frames**: 5 frames (reduced from 36).

| Animation State | Frames | Loop | Description | Urgency |
|---|---|---|---|---|
| `Idle` | 0 - 1 | Yes | Slow core breathing light. | Critical |
| `Attack` | 2 - 3 | No | Pulls back, punches forward. | Critical |
| `Hit / Die` | 4 | No | Shakes back with sparks. Reused for defeat. | Critical |

### Paper Monster (Exam Sheet Golem)
- **Dimensions**: 96 x 96 pixels.
- **Total Frames**: 5 frames (reduced from 36).

| Animation State | Frames | Loop | Description | Urgency |
|---|---|---|---|---|
| `Idle` | 0 - 1 | Yes | Fluttering pages. | Critical |
| `Attack` | 2 - 3 | No | Lunges forward like a paper blade. | Critical |
| `Hit / Die` | 4 | No | Torn pages flying loose. Reused for defeat. | Critical |

### Castle Boss (Mechanical Core)
- **Dimensions**: 128 x 128 pixels.
- **Total Frames**: 5 frames (reduced from 40).

| Animation State | Frames | Loop | Description | Urgency |
|---|---|---|---|---|
| `Idle` | 0 - 1 | Yes | Main central gear rotation. | Critical |
| `Attack` | 2 - 3 | No | Slams down to generate shockwave. | Critical |
| `Hit / Die` | 4 | No | Armor plate buckling. Reused for defeat. | Critical |

### Feral Wolf / Pack Leader (Beasts)
- **Dimensions**: Feral Wolf (64 x 48 pixels), Pack Leader Boss (128 x 96 pixels).
- **Total Frames**: 5 frames each.
- **Urgency**: High.
- **Palette Swap Rule**: The game has only one set of wolf assets. The Feral Wolf, Beta Wolf, and Pack Leader use the exact same sprite sheets, scaled or programmatically color-shifted in Godot to save art pipeline assets.

*Note: Sentry minor defenders are cut. Code will use standard Gear Golems in their place.*

---

## 6. Shared Card Illustrations

To save illustration pipeline time, the 8 game cards are grouped to share 4 common illustration panels (96 x 64 pixels, monochrome sketch style).

| Card Name | Shared Illustration Asset | Visual Composition | Urgency |
|---|---|---|---|
| `Strike` / `Double Strike` | `slash_illustration` | A sharp, diagonal white line cutting across a dark charcoal background. Double Strike mirrors or offsets the image. | Critical |
| `Defend` / `Fortress` / `Counter Stance` | `shield_illustration` | A simple isometric drawing of a buckler shield with thin grid/blueprint guidelines overlaying it. | Critical |
| `Fireball` | `flame_illustration` | A silhouetted hand holding a rough, circular scribble representing a flame ball. | Critical |
| `Thunder` | `lightning_illustration` | A single jagged lightning bolt striking down onto a flat horizontal landscape line. | High |

*Note: Heavy Slash reuses `slash_illustration` with a dark red tint applied in Godot.*

---

## 7. UI and HUD Asset Workload Reductions (The UI Atlas Middle Ground)

To prevent plain vector UI boxes from clashing with the low-resolution retro pixel art, the game uses a middle-ground approach: a single modular UI Atlas Sheet. Instead of drawing separate mockups for every button, panel, and bar size, the art team delivers one tiny sheet containing reusable tiles. The developer loads these into Godot using **StyleBoxTexture (9-Patch Slices)**, which stretches the center of the textures while keeping the hand-drawn pixelated borders crisp and undistorted.

### UI Atlas Sheet Assets to DRAW (One Single Texture File, e.g. 128 x 128 pixels):
1. **Dream Panel Frame** (24 x 24 pixels, 9-patch sliced at 8px margins)
   - Warm parchment beige fill with a rough, hand-drawn charcoal border. Reused for dialogue textboxes, stats boxes, and booklets in the Dream.
2. **Reality Panel Frame** (24 x 24 pixels, 9-patch sliced at 8px margins)
   - Translucent dark slate grey fill with a thin, sharp white outline. Reused for UI textboxes and menu panels in Reality.
3. **Modular Button Frame** (3 states: Normal, Hover, and Pressed; 32 x 12 pixels each, 9-patch sliced at 4px margins)
   - Stylized paper tag or slate plate. Godot stretches this horizontally to fit any text length (End Turn, Shift, Reroll, settings options).
4. **Progress Bar Frame and Fill Slices**
   - Frame (16 x 6 pixels, sliced at 2px margins): Simple hollow border slot.
   - Fills (8 x 4 pixels, tiling): Green fill (HP), blue fill (Shield), red fill (HP catchup).
5. **Reroll / Recycle Icon** (12 x 12 pixels)
   - A tiny hand-drawn recycling arrow symbol. Placed inside buttons.

### Standalone UI Assets to DRAW:
1. **`card_template`** (140 x 200 pixels) - 9-patch outline frame texture. Features a central illustration frame box (96x64), a title banner slot at the top, and a description slot at the bottom. (Urgency: Critical)
2. **`block_icon`** (16 x 16 pixels) - Simple shield vector icon. (Urgency: Critical)
3. **`card_pile_icon`** (32 x 32 pixels) - Simple icon showing a stack of drawing paper. Reused in Godot for both the Draw Pile (bottom-left) and Discard Pile (bottom-right). (Urgency: Critical)

### UI Configured Programmatically via Atlas in Godot:
- **Textbox Background & Speaker Badges**: Configured using `StyleBoxTexture` referencing the Dream/Reality panel tiles.
- **Buttons (End Turn, Shift, Reroll)**: Normal/hover/pressed button styles referencing the modular button frame.
- **HP / Shield Bars**: Textures using the progress bar frame and tiling fills.
- **Victory / Defeat Screens**: Plain panel backgrounds scaled from the atlas, overlayed with large text using pixelated retro fonts.
- **Continuing Arrow**: Text-based arrow symbol "▼" pulsing via Tween.

---

## 8. Particle FX and Narrative Cutscenes

### Particle Effects
Instead of drawing frame-by-frame pixel-art animation sheets, the game relies on Godot's built-in particles:
- **`slash_impact`**: A simple 3-frame slash sprite sheet (64 x 64 pixels). (Urgency: Critical)
- **Other Effects (Shield Flash, Spark Recoil, Fireball Impact, Lightning Strike)**: Created programmatically in Godot using `CPUParticles2D` emitting small square/clump particles and scaling `Line2D` nodes with tweens.

### Narrative Cutscenes
Only 2 static narrative screens are required:
1. **`dream_ending_illustration`** (512 x 208 pixels) - Static 1-frame grayscale sketch of Hilbert and n.n. under a sun gear. (Urgency: High)
2. **`wake_ending_illustration`** (512 x 208 pixels) - Static 1-frame grayscale sketch of Hilbert's open hand with the rusted mechanical core of n.n. (Urgency: High)

*Note: The accident memory illustration is cut from the artwork pipeline.*
