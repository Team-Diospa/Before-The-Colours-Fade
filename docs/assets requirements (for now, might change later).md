# Sprite and Illustration Asset Requirements Guide

This document lists the required sprites, illustrations, dimensions, and animation frame breakdowns for the game.

---

## 1. Technical Resolution and Scaling Specifications

The game displays in a standard 16:9 window (1152 x 648 viewport). To maintain a sharp, low-resolution retro pixel-art style, we author assets at a native resolution and scale them up programmatically:
- **Base Environment Height**: 180 pixels.
- **Base Environment Width**: 410 pixels (fits screen width) or longer (e.g. 820 pixels for horizontal scrolling levels).
- **Godot Scale Factor**: 3.6x (scaling 180px height to fit the 648px vertical viewport height).
- **Ground Floor Line**: Y = 144 in raw textures (corresponds to Y = 520 in the scaled Godot scene). This leaves 36 pixels of ground clearance for character sprites to stand on.
- **Filtering**: Default texture filtering must be set to **Nearest** to prevent linear blur.

---

## 2. Exploration Backgrounds

These backgrounds represent the scrollable play areas. The height is fixed at 180 pixels, and the width supports horizontal scrolling where necessary.

| Asset Name | Type | Base Dimensions | Description | Priority |
|---|---|---|---|---|
| `bedroom_bg` | Background Sprite | 410 x 180 | Hilbert's apartment. Features a bed, wardrobe, desk, window, and kitchen area. Ground floor at Y = 144. | High |
| `classroom_bg` | Background Sprite | 410 x 180 | Sterile university lecture room. Features rows of desks, blackboard, and professor podium. Ground floor at Y = 144. | High |
| `hallway_bg` | Background Sprite | 410 x 180 | University corridor. Features school lockers, water fountain, and office doors. Ground floor at Y = 144. | High |
| `grassy_field_bg` | Background Sprite | 410 x 180 | Dream world field. Sky is represented by vector-style circular lines and a large sun gear. Ground floor is rough grassy soil. | High |
| `burning_village_bg` | Background Sprite | 410 x 180 | Dream world village. Features silhouetted burning houses, smoke particles, and ash-covered earth ground. | High |

---

## 3. Interactive Exploration Objects

These individual sprites are placed on the background and support mouse hovering (pencil jitter outline) and targeting overlays.

| Object Name | Dimensions | Static Frame | Pencil Jitter Frames | Active / Operating State | Description | Priority |
|---|---|---|---|---|---|---|
| `bed` | 96 x 64 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Hilbert asleep under sheets. | Messy single bed. | High |
| `wardrobe` | 48 x 80 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 8 (one-shot): Wardrobe doors open. | Tall wooden wardrobe. | High |
| `desk_apartment` | 64 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Desk lamp glow flickering. | Littered study desk. | High |
| `guitar` | 32 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 8 (loop): String vibration lines. | Acoustic guitar. | Medium |
| `window` | 80 x 96 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 12 (loop): Rain droplets sliding down. | Apartment window view. | Medium |
| `papers` | 32 x 16 | Frame 0 | Frames 1 - 4 (loop) | None | Blueprint sheets on floor. | Medium |
| `shower` | 48 x 80 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Water drop particles. | Glass shower stall. | Low |
| `toilet` | 32 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 9 (one-shot): Flushing water vortex. | White toilet bowl. | Low |
| `kitchen` | 96 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Kettle boiling steam. | Sink and kitchen counter. | Low |
| `locker` | 32 x 80 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 8 (one-shot): Door swings open. | Hallway metal locker. | Medium |
| `blackboard` | 120 x 60 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 12 (one-shot): Chalk text drawing itself. | University board. | Medium |

---

## 4. Character Sprite Sheets

All character sprite sheets use a grid layout. Each frame is bounded by a fixed box to ensure alignment during import.

### Hilbert (Player Character)
- **Dimensions**: 32 x 32 pixels per frame.
- **Layout**: Grid of 4 columns, 9 rows (36 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 3 | Yes | Breathing motion, hair moving slightly. | High |
| `Walk` | 4 - 9 | Yes | 6-frame walking cycle with swinging arms. | High |
| `Interact / Reach` | 10 - 13 | No | Reaches out hand to operate objects. | High |
| `Inspect / Read` | 14 - 17 | Yes | Stands with head tilted down, reading a notebook. | High |
| `Stress / Shake` | 18 - 23 | Yes | Hilbert trembling, arms held to chest. | High |
| `Shift / Dissolve` | 24 - 33 | No | Dissolves into loose pencil lines during transitions. | High |
| `Lying Down / Sleep` | 34 - 35 | Yes | Static sleeping state used when resting in bed. | High |

### Peer 1 (Classroom NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 3 rows (12 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Sitting / Tired` | 0 - 3 | Yes | Sitting at desk, head nodding down in exhaustion. | High |
| `Talking` | 4 - 7 | Yes | Subtle mouth and hand gestures while speaking. | High |
| `Idle / Standing` | 8 - 11 | Yes | Standing idle state with arms crossed. | High |

### Peer 2 (Classroom NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 3 rows (12 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Sitting / Writing` | 0 - 3 | Yes | Writing on test paper, pencil moving in hand. | High |
| `Glancing / Annoyed` | 4 - 7 | Yes | Head turning to look at Hilbert with a frown. | High |
| `Talking` | 8 - 11 | Yes | Speaking with defensive hand gestures. | High |

### Professor (Classroom NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 2 rows (8 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Lecturing / Standing` | 0 - 3 | Yes | Standing behind the podium, gesturing to board. | Medium |
| `Glaring / Checking` | 4 - 7 | Yes | Looking up from notes, checking classroom. | Medium |

### Landlady (Hallway NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 2 rows (8 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Standing Idle` | 0 - 3 | Yes | Standing near door, shifting weight slowly. | Medium |
| `Talking` | 4 - 7 | Yes | Shaking head or gesturing while speaking. | Medium |

---

## 5. Combat Golems and Enemies

All combat enemies require loops for turn-based idle, attacks, hit reactions, and death dissolving.

### Monster Base (Standard Gear Golem)
- **Dimensions**: 96 x 96 pixels.
- **Layout**: Grid of 6 columns, 6 rows (36 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Gears rotating, steam puffing from exhaust vents. | High |
| `Anticipate` | 6 - 9 | No | Core glowing, gears spinning faster. | High |
| `Attack` | 10 - 17 | No | Punches forward, venting a cloud of hot steam. | High |
| `Hit` | 18 - 21 | No | Reels back, chest plate opening with sparks. | High |
| `Die` | 22 - 33 | No | Golem collapses, gears scattering, fading to dust. | High |

### Paper Monster (Exam Sheet Golem)
- **Dimensions**: 96 x 96 pixels.
- **Layout**: Grid of 6 columns, 6 rows (36 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Pages fluttering in place, hovering slightly. | High |
| `Anticipate` | 6 - 9 | No | Pages gathering tightly into a dense core. | High |
| `Attack` | 10 - 17 | No | Pages slice forward like paper blades. | High |
| `Hit` | 18 - 21 | No | Sheets scatter outward, flying loose before reforming. | High |
| `Die` | 22 - 33 | No | Pages tear apart, dissolving into ink splashes. | High |

### Sentry (Castle Minor Defender)
- **Dimensions**: 64 x 64 pixels.
- **Layout**: Grid of 4 columns, 4 rows (16 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 3 | Yes | Hovering gear shield, core throbbing with light. | Medium |
| `Attack` | 4 - 9 | No | Spins core shield forward, shooting iron bolts. | Medium |
| `Hit` | 10 - 12 | No | Core dimming, armor shards chipping off. | Medium |
| `Die` | 13 - 15 | No | Gear shield shattering and falling to the ground. | Medium |

### Castle Boss (Mechanical Core)
- **Dimensions**: 128 x 128 pixels.
- **Layout**: Grid of 8 columns, 5 rows (40 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 7 | Yes | Large central gear spinning, plates shifting. | High |
| `Anticipate` | 8 - 13 | No | Overheating warning lights flashing. | High |
| `Attack` | 14 - 23 | No | Slams down, creating a ground shockwave. | High |
| `Hit` | 24 - 29 | No | Outer armor plates buckling, crack lines appearing. | High |
| `Die` | 30 - 39 | No | Core implodes, collapsing into iron debris. | High |

### Feral Wolf (Village Minor Beast)
- **Dimensions**: 64 x 48 pixels.
- **Layout**: Grid of 6 columns, 4 rows (24 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Growling stance, body breathing heavily. | High |
| `Attack` | 6 - 11 | No | Leaps forward, biting with jaw snap. | High |
| `Hit` | 12 - 15 | No | Reeling back, head shaking. | High |
| `Die` | 16 - 23 | No | Collapses and crumbles into loose pencil strokes. | High |

### Beta Wolf (Village Pack Defender)
- **Dimensions**: 80 x 64 pixels.
- **Layout**: Grid of 6 columns, 4 rows (24 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Stalking stance, red eyes glowing with graphite dust. | High |
| `Attack` | 6 - 11 | No | Claws sweep forward, creating slashing vectors. | High |
| `Hit` | 12 - 15 | No | Shaking head, body cringing back. | High |
| `Die` | 16 - 23 | No | Shatters into loose drawing segments. | High |

### Pack Leader (Village Boss Beast)
- **Dimensions**: 128 x 96 pixels.
- **Layout**: Grid of 8 columns, 4 rows (32 frames total).

| Animation State | Frames | Loop | Description | Priority |
|---|---|---|---|---|
| `Idle` | 0 - 7 | Yes | Giant wolf standing tall, dark smoke rising from coat. | High |
| `Anticipate` | 8 - 11 | No | Howling to sky, eyes shining with intense light. | High |
| `Attack` | 12 - 19 | No | Lunges forward, tearing with massive claw swipes. | High |
| `Hit` | 20 - 23 | No | Reels back, dark smoke venting out of joints. | High |
| `Die` | 24 - 31 | No | Wolf collapses, dissolving into thick graphite storm. | High |

---

## 6. Card Illustrations

Every card requires a unique illustration panel (96 x 64 pixels base size) inside the card frame. The style is a minimalist, single-color pencil or blueprint sketch.

| Card Name | Asset File | Illustration Style | Visual Composition Description | Priority |
|---|---|---|---|---|
| `Strike` | `strike.tres` | Charcoal Pencil | A simple hand-drawn sword blade executing a downward slashing vector. | High |
| `Defend` | `defend.tres` | Charcoal Pencil | A simple wooden buckler shield with rough sketch grain texture. | High |
| `Double Strike` | `double_strike.tres` | Charcoal Pencil | Two overlapping sword slash vectors crossing each other. | High |
| `Fireball` | `fireball.tres` | Graphite Scribble | A rough hand holding a small glowing sphere venting pencil smoke particles. | High |
| `Fortress` | `fortress.tres` | Blueprint Draft | A technical double-braced wall framing drawing with structural annotations. | High |
| `Heavy Slash` | `heavy_slash.tres` | Charcoal Pencil | A massive diagonal slash arc line crushing a simple block object. | High |
| `Counter Stance` | `counter_stance.tres` | Blueprint Draft | A technical mechanical diagram of a spring-loaded recoil gear. | High |
| `Thunder` | `thunder.tres` | Graphite Scribble | A jagged electric bolt cutting down to a flat grid horizon line. | High |

---

## 7. UI Elements and Iconography

These UI sprites build the deckbuilder panels, HUD bar, booklet viewer tabs, and buttons. They must align with the nearest-neighbor pixel grid.

| UI Asset Name | Dimensions | States | Description | Priority |
|---|---|---|---|---|
| `card_template` | 140 x 200 | Normal, Hovered, Dragged | Card paper background, border line, and title text slot. | High |
| `energy_orb` | 48 x 48 | Normal, Empty | Circular clockwork axle gear indicator representing combat energy. | High |
| `block_icon` | 24 x 24 | Static | Shield vector silhouette showing starting block points. | High |
| `targeting_arrow` | 32 x 32 (varies) | Animated | Sienna/orange hand-drawn arrow pointing to targeted enemy. | High |
| `draw_pile_icon` | 48 x 48 | Empty, Normal, Full | A mini stack of drawing sheets on the lower-left. | High |
| `discard_pile_icon`| 48 x 48 | Empty, Normal, Full | A messy pile of crumpled drawing paper sheets on lower-right. | High |
| `booklet_btn` | 32 x 32 | Normal, Hover, Pressed | Mini book icon used to toggle the master deck Booklet. | High |
| `top_hud_bar` | 1152 x 40 | Static | Sienna top horizontal border displaying waves and gold points. | High |
| `end_turn_btn` | 96 x 32 | Normal, Hover, Pressed | A rough paper label button representing turn submission. | High |
| `shift_btn` | 80 x 32 | Normal, Hover, Pressed | A hand-drawn double arrow symbol to shift dimensions. | High |
| `reroll_btn` | 80 x 32 | Normal, Hover, Pressed | A circular hand-drawn recycling arrow to swap cards. | High |
| `turn_banner` | 400 x 80 | Fade-in / Fade-out | "Player Turn" or "Enemy Turn" text written in chalk font. | High |

---

## 8. Combat Visual Particle Effects (FX)

Visual effects spawned on top of characters/enemies when cards are played or damage is resolved. Drawn as sprite sheet frame animations with transparent backgrounds.

| FX Asset Name | Dimensions | Frame Count | Loop | Description | Priority |
|---|---|---|---|---|---|
| `slash_impact` | 64 x 64 | 5 frames | No | Sharp white diagonal cut line appearing and dissolving. | High |
| `double_slash_impact`| 64 x 64 | 8 frames | No | Two quick crossing slash vectors flashing in sequence. | High |
| `shield_flash` | 64 x 64 | 4 frames | No | Semi-translucent sienna shield contour expanding slightly. | High |
| `spark_recoil` | 48 x 48 | 5 frames | No | Small explosion sparks flying outward in sharp angles. | Medium |
| `fireball_impact` | 96 x 96 | 10 frames | No | Fireball expanding into a smoky pixel cloud and vanishing. | High |
| `lightning_strike` | 64 x 128 | 8 frames | No | Electrical branch flashing down from top of screen to ground. | High |

---

## 9. Narrative Cutscene Illustrations

Static, full-screen retro pixel artworks (512 x 288 pixels) displaying during cutscenes and endings.

1. `dream_ending_illustration` (Priority: Medium):
   - **Composition**: Hilbert standing in a bright sienna field under a sun gear. n.n. is perched on his shoulder, propellor spinning.
   - **Details**: Character details are simplified into clean black pencil strokes.
2. `wake_ending_illustration` (Priority: Medium):
   - **Composition**: A close-up of Hilbert's open hand. The metal form of n.n. lies rusted and cracked, crumbling into red dust.
   - **Details**: Background is a dark slate void with tiny floating grey motes.
3. `accident_memory_illustration` (Priority: Low):
   - **Composition**: Rain-slicked road at night. The high-contrast glare of vehicle headlights is reflected in the water, cast against dark silhouettes.
   - **Details**: Monochromatic grey/blue tones with single desaturated amber accents.
