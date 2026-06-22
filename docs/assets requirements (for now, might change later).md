# Sprite and Illustration Asset Requirements Guide

This document lists the required sprites, illustrations, dimensions, and animation frame breakdowns for the game.

---

## 1. Technical Resolution and Scaling Specifications

The game displays in a standard 16:9 window (1152 x 648 viewport). To maintain a sharp, low-resolution retro pixel-art style, all backgrounds, cutscenes, and assets are authored at a native resolution and scaled up programmatically:
- **Base Environment Height**: 208 pixels.
- **Base Environment Width**: 512 pixels (or wider, e.g. 1024 pixels for horizontal scrolling levels).
- **Narrative Cutscenes**: Fixed at 512 x 208 pixels to match the environmental assets, preventing aspect ratio distortion and ensuring uniform scaling.
- **Godot Scale Factor**: 3.115x (scaling 208px height to fit the 648px vertical viewport height).
- **Ground Floor Line**: Y = 166 in raw textures (corresponds to Y = 520 in the scaled Godot scene). This leaves 42 pixels of ground clearance for character sprites to stand on.
- **Filtering**: Default texture filtering must be set to Nearest to prevent linear blur.

---

## 2. Urgency Tiers for Asset Production

To align asset creation with development milestones, all sprites, backgrounds, and UI elements are assigned an Urgency Tier:
- **Tier 1: Core Systems & Tutorial (Critical)**: Essential assets required for the core game loop, basic player movement, tutorial combat, and main HUD/Dialogue boxes.
- **Tier 2: Chapter 1 Progression & Core Battle Loop (High)**: Assets needed for the first complete chapter (Classroom environment, Professor, first wave of combat encounters, boss fight).
- **Tier 3: Chapter 2 Progression & Wolf Encounter (Medium)**: Assets for the subsequent chapter (Hallway environment, Landlady, Village battle, Pack Leader boss fight, and ending cutscenes).
- **Tier 4: Polish & Optional Interactions (Low)**: Non-essential interactive objects, cosmetic details, and supplementary cutscene frames.

---

## 3. Exploration and Combat Backgrounds

These backgrounds represent the play areas. The height is fixed at 208 pixels, and the width supports horizontal scrolling.

| Asset Name | Type | Base Dimensions | Description | Urgency Tier |
|---|---|---|---|---|
| `bedroom_bg` | Background Sprite | 512 x 208 | Hilbert's apartment. Features a bed, wardrobe, desk, window, and kitchen area. Ground floor at Y = 166. | Tier 1 (Tutorial Area) |
| `classroom_bg` | Background Sprite | 512 x 208 | Sterile university lecture room. Features rows of desks, blackboard, and professor podium. Ground floor at Y = 166. | Tier 2 (Chapter 1 Core) |
| `grassy_field_bg` | Background Sprite | 512 x 208 | Dream world grassy field. Sky is represented by vector-style circular lines and a large sun gear. | Tier 2 (Chapter 1 Battle) |
| `hallway_bg` | Background Sprite | 512 x 208 | University corridor. Features school lockers, water fountain, and office doors. Ground floor at Y = 166. | Tier 3 (Chapter 2 Core) |
| `burning_village_bg` | Background Sprite | 512 x 208 | Dream world village. Features silhouetted burning houses, smoke particles, and ash-covered earth. | Tier 3 (Chapter 2 Battle) |

---

## 4. Interactive Exploration Objects

These individual sprites are placed on the background and support mouse hovering (pencil jitter outline) and targeting overlays.

| Object Name | Dimensions | Static Frame | Pencil Jitter Frames | Active / Operating State | Description | Urgency Tier |
|---|---|---|---|---|---|---|
| `bed` | 96 x 64 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Hilbert asleep under sheets. | Messy single bed. | Tier 1 (Tutorial Core) |
| `wardrobe` | 48 x 80 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 8 (one-shot): Wardrobe doors open. | Tall wooden wardrobe. | Tier 1 (Tutorial Core) |
| `desk_apartment` | 64 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Desk lamp glow flickering. | Littered study desk. | Tier 1 (Tutorial Core) |
| `blackboard` | 120 x 60 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 12 (one-shot): Chalk text drawing itself. | University board. | Tier 2 (Chapter 1 Core) |
| `locker` | 32 x 80 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 8 (one-shot): Door swings open. | Hallway metal locker. | Tier 3 (Chapter 2 Core) |
| `window` | 80 x 96 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 12 (loop): Rain droplets sliding down. | Apartment window view. | Tier 3 (Aesthetic) |
| `guitar` | 32 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 8 (loop): String vibration lines. | Acoustic guitar. | Tier 3 (Aesthetic) |
| `papers` | 32 x 16 | Frame 0 | Frames 1 - 4 (loop) | None | Blueprint sheets on floor. | Tier 3 (Aesthetic) |
| `shower` | 48 x 80 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Water drop particles. | Glass shower stall. | Tier 4 (Optional Decor) |
| `toilet` | 32 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 9 (one-shot): Flushing water vortex. | White toilet bowl. | Tier 4 (Optional Decor) |
| `kitchen` | 96 x 48 | Frame 0 | Frames 1 - 4 (loop) | Frames 5 - 10 (loop): Kettle boiling steam. | Sink and kitchen counter. | Tier 4 (Optional Decor) |

---

## 5. Character Sprite Sheets

All character sprite sheets use a grid layout. Each frame is bounded by a fixed box to ensure alignment during import.

### Hilbert (Player Character)
- **Dimensions**: 32 x 32 pixels per frame.
- **Layout**: Grid of 4 columns, 9 rows (36 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 3 | Yes | Breathing motion, hair moving slightly. | Tier 1 (Core Player) |
| `Walk` | 4 - 9 | Yes | 6-frame walking cycle with swinging arms. | Tier 1 (Core Player) |
| `Interact / Reach` | 10 - 13 | No | Reaches out hand to operate objects. | Tier 1 (Core Player) |
| `Lying Down / Sleep` | 34 - 35 | Yes | Static sleeping state used when resting in bed. | Tier 1 (Core Player) |
| `Inspect / Read` | 14 - 17 | Yes | Stands with head tilted down, reading a notebook. | Tier 2 (Story Beat) |
| `Stress / Shake` | 18 - 23 | Yes | Hilbert trembling, arms held to chest. | Tier 2 (Story Beat) |
| `Shift / Dissolve` | 24 - 33 | No | Dissolves into loose pencil lines during transitions. | Tier 2 (Combat Transition) |

### Peer 1 (Classroom NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 3 rows (12 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Sitting / Tired` | 0 - 3 | Yes | Sitting at desk, head nodding down in exhaustion. | Tier 2 (Chapter 1 Scene) |
| `Talking` | 4 - 7 | Yes | Subtle mouth and hand gestures while speaking. | Tier 2 (Chapter 1 Scene) |
| `Idle / Standing` | 8 - 11 | Yes | Standing idle state with arms crossed. | Tier 2 (Chapter 1 Scene) |

### Peer 2 (Classroom NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 3 rows (12 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Sitting / Writing` | 0 - 3 | Yes | Writing on test paper, pencil moving in hand. | Tier 2 (Chapter 1 Scene) |
| `Glancing / Annoyed` | 4 - 7 | Yes | Head turning to look at Hilbert with a frown. | Tier 2 (Chapter 1 Scene) |
| `Talking` | 8 - 11 | Yes | Speaking with defensive hand gestures. | Tier 2 (Chapter 1 Scene) |

### Professor (Classroom NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 2 rows (8 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Lecturing / Standing` | 0 - 3 | Yes | Standing behind the podium, gesturing to board. | Tier 2 (Classroom Core) |
| `Glaring / Checking` | 4 - 7 | Yes | Looking up from notes, checking classroom. | Tier 2 (Classroom Core) |

### Landlady (Hallway NPC)
- **Dimensions**: 32 x 48 pixels per frame.
- **Layout**: Grid of 4 columns, 2 rows (8 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Standing Idle` | 0 - 3 | Yes | Standing near door, shifting weight slowly. | Tier 3 (Hallway Core) |
| `Talking` | 4 - 7 | Yes | Shaking head or gesturing while speaking. | Tier 3 (Hallway Core) |

---

## 6. Combat Golems and Enemies

All combat enemies require loops for turn-based idle, attacks, hit reactions, and death dissolving.

### Monster Base (Standard Gear Golem)
- **Dimensions**: 96 x 96 pixels.
- **Layout**: Grid of 6 columns, 6 rows (36 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Gears rotating, steam puffing from exhaust vents. | Tier 1 (Tutorial Combat) |
| `Anticipate` | 6 - 9 | No | Core glowing, gears spinning faster. | Tier 1 (Tutorial Combat) |
| `Attack` | 10 - 17 | No | Punches forward, venting a cloud of hot steam. | Tier 1 (Tutorial Combat) |
| `Hit` | 18 - 21 | No | Reels back, chest plate opening with sparks. | Tier 1 (Tutorial Combat) |
| `Die` | 22 - 33 | No | Golem collapses, gears scattering, fading to dust. | Tier 1 (Tutorial Combat) |

### Paper Monster (Exam Sheet Golem)
- **Dimensions**: 96 x 96 pixels.
- **Layout**: Grid of 6 columns, 6 rows (36 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Pages fluttering in place, hovering slightly. | Tier 2 (Chapter 1 Combat) |
| `Anticipate` | 6 - 9 | No | Pages gathering tightly into a dense core. | Tier 2 (Chapter 1 Combat) |
| `Attack` | 10 - 17 | No | Pages slice forward like paper blades. | Tier 2 (Chapter 1 Combat) |
| `Hit` | 18 - 21 | No | Sheets scatter outward, flying loose before reforming. | Tier 2 (Chapter 1 Combat) |
| `Die` | 22 - 33 | No | Pages tear apart, dissolving into ink splashes. | Tier 2 (Chapter 1 Combat) |

### Castle Boss (Mechanical Core)
- **Dimensions**: 128 x 128 pixels.
- **Layout**: Grid of 8 columns, 5 rows (40 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 7 | Yes | Large central gear spinning, plates shifting. | Tier 2 (Chapter 1 Boss) |
| `Anticipate` | 8 - 13 | No | Overheating warning lights flashing. | Tier 2 (Chapter 1 Boss) |
| `Attack` | 14 - 23 | No | Slams down, creating a ground shockwave. | Tier 2 (Chapter 1 Boss) |
| `Hit` | 24 - 29 | No | Outer armor plates buckling, crack lines appearing. | Tier 2 (Chapter 1 Boss) |
| `Die` | 30 - 39 | No | Core implodes, collapsing into iron debris. | Tier 2 (Chapter 1 Boss) |

### Sentry (Castle Minor Defender)
- **Dimensions**: 64 x 64 pixels.
- **Layout**: Grid of 4 columns, 4 rows (16 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 3 | Yes | Hovering gear shield, core throbbing with light. | Tier 2 (Chapter 1 Encounter) |
| `Attack` | 4 - 9 | No | Spins core shield forward, shooting iron bolts. | Tier 2 (Chapter 1 Encounter) |
| `Hit` | 10 - 12 | No | Core dimming, armor shards chipping off. | Tier 2 (Chapter 1 Encounter) |
| `Die` | 13 - 15 | No | Gear shield shattering and falling to the ground. | Tier 2 (Chapter 1 Encounter) |

### Feral Wolf (Village Minor Beast)
- **Dimensions**: 64 x 48 pixels.
- **Layout**: Grid of 6 columns, 4 rows (24 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Growling stance, body breathing heavily. | Tier 3 (Chapter 2 Encounter) |
| `Attack` | 6 - 11 | No | Leaps forward, biting with jaw snap. | Tier 3 (Chapter 2 Encounter) |
| `Hit` | 12 - 15 | No | Reeling back, head shaking. | Tier 3 (Chapter 2 Encounter) |
| `Die` | 16 - 23 | No | Collapses and crumbles into loose pencil strokes. | Tier 3 (Chapter 2 Encounter) |

### Beta Wolf (Village Pack Defender)
- **Dimensions**: 80 x 64 pixels.
- **Layout**: Grid of 6 columns, 4 rows (24 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 5 | Yes | Stalking stance, red eyes glowing with graphite dust. | Tier 3 (Chapter 2 Encounter) |
| `Attack` | 6 - 11 | No | Claws sweep forward, creating slashing vectors. | Tier 3 (Chapter 2 Encounter) |
| `Hit` | 12 - 15 | No | Shaking head, body cringing back. | Tier 3 (Chapter 2 Encounter) |
| `Die` | 16 - 23 | No | Shatters into loose drawing segments. | Tier 3 (Chapter 2 Encounter) |

### Pack Leader (Village Boss Beast)
- **Dimensions**: 128 x 96 pixels.
- **Layout**: Grid of 8 columns, 4 rows (32 frames total).

| Animation State | Frames | Loop | Description | Urgency Tier |
|---|---|---|---|---|
| `Idle` | 0 - 7 | Yes | Giant wolf standing tall, dark smoke rising from coat. | Tier 3 (Chapter 2 Boss) |
| `Anticipate` | 8 - 11 | No | Howling to sky, eyes shining with intense light. | Tier 3 (Chapter 2 Boss) |
| `Attack` | 12 - 19 | No | Lunges forward, tearing with massive claw swipes. | Tier 3 (Chapter 2 Boss) |
| `Hit` | 20 - 23 | No | Reels back, dark smoke venting out of joints. | Tier 3 (Chapter 2 Boss) |
| `Die` | 24 - 31 | No | Wolf collapses, dissolving into thick graphite storm. | Tier 3 (Chapter 2 Boss) |

---

## 7. Combat Card Detailed Specifications

Every combat card requires its properties and visual styling detailed to ensure clean engine translation. Cards are structured as `CardData` resources.

```
+------------------------------------------+
|  [1] Energy Cost Badge (16 x 16 px)      |
|  Card Name: Strike                       |
|  Card Type: Attack                       |
+------------------------------------------+
|                                          |
|  Illustration Panel (96 x 64 px)         |
|  - Raw drawing inside a single-pixel     |
|    border                                |
|                                          |
+------------------------------------------+
|  Description Text Container              |
|  - "Deal 6 damage to single target."     |
|                                          |
+------------------------------------------+
```

### 1. Strike
- **Resource Path**: [strike.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/strike.tres)
- **Card Properties**:
  - Type: Attack
  - Cost: 1 Energy
  - Base Value: 6
  - Target Mode: single
- **Gameplay Description Text**: "Deal 6 damage to single target"
- **Illustration Composition**: Charcoal Pencil style. A sharp, high-contrast diagonal white slash line cuts across the center of a square black container panel, with flying graphite particles radiating outwards at the impact point.
- **Card Frame Layout**: The card frame uses sienna pencil borders. The top-left features a small circle enclosing the numeral 1. Below the title is the 96x64 illustration window. The bottom half contains the description text aligned to the center.
- **Under-the-Hood Scaling Logic**: Damage scales with active player buffs: multiplies by 2.0x if Confidence is active, and 1.5x if Courage is active.
- **Visual FX & Sounds**: Plays `slash_impact` particle FX on the target node. Triggers a minor camera shake of 3 pixels for 0.15 seconds. Plays a sharp canvas tearing sound cue.
- **Urgency Tier**: Tier 1 (Critical)

### 2. Defend
- **Resource Path**: [defend.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/defend.tres)
- **Card Properties**:
  - Type: Defense
  - Cost: 1 Energy
  - Base Value: 6
  - Target Mode: self
- **Gameplay Description Text**: "Gain 6 block"
- **Illustration Composition**: Charcoal Pencil style. A wooden buckler shield drawn from a 3/4 isometric perspective, showcasing deep wood-grain scratch textures and curved iron bindings across the front face.
- **Card Frame Layout**: Sienna pencil border. The top-left badge shows the cost of 1. The illustration window sits in the center. The description text is printed in a clean charcoal font at the bottom.
- **Under-the-Hood Scaling Logic**: Applies 6 points of block directly to the player node's current block value. Does not scale with attack multipliers.
- **Visual FX & Sounds**: Plays `shield_flash` particle FX on the player node. Plays a dull wooden impact sound cue.
- **Urgency Tier**: Tier 1 (Critical)

### 3. Double Strike
- **Resource Path**: [double_strike.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/double_strike.tres)
- **Card Properties**:
  - Type: Attack
  - Cost: 1 Energy
  - Base Value: 8
  - Target Mode: single
- **Gameplay Description Text**: "Deal 4 damage twice"
- **Illustration Composition**: Charcoal Pencil style. Two crossing vector slash lines at a 45-degree angle forming an X, with the intersection showing a glowing white impact point and radiating shock lines.
- **Card Frame Layout**: Sienna pencil border. Top-left cost badge shows 1. The illustration window is framed by a thin double-line border. Description text sits in the bottom container.
- **Under-the-Hood Scaling Logic**: Splits the base damage of 8 into two separate damage applications of 4. Each hit evaluates the target's block value individually. Damage scales by 2.0x (Confidence) or 1.5x (Courage) per hit.
- **Visual FX & Sounds**: Triggers two consecutive instances of the `double_slash_impact` FX on the target spaced 0.12 seconds apart. Plays a rapid double slicing sound cue.
- **Urgency Tier**: Tier 2 (High)

### 4. Fireball
- **Resource Path**: [fireball.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/fireball.tres)
- **Card Properties**:
  - Type: Attack
  - Cost: 2 Energy
  - Base Value: 8
  - Target Mode: all
- **Gameplay Description Text**: "Deal 8 damage to all targets. Targets burn, cancelling their next block intent."
- **Illustration Composition**: Graphite Scribble style. A hand shown in silhouette from the wrist, with fingers curled upward holding a central, crackling energy sphere. The sphere has loose circular scribble lines radiating outward to represent heat waves.
- **Card Frame Layout**: Slate border (reality/dream transition style). The cost badge shows 2. The central illustration window is larger than normal (98x66) to emphasize the heat waves. The description text wraps dynamically across three lines at the bottom.
- **Under-the-Hood Scaling Logic**: Deals base damage of 8 to all active enemies, scaled by player damage multipliers. Sets the global flag `enemy_burning` to true and calls the player target's `cancel_enemy_defend()` method to force them into an Attack state.
- **Visual FX & Sounds**: Spawns `fireball_impact` on all targets simultaneously. Plays a heavy bass wave rumble sound cue.
- **Urgency Tier**: Tier 2 (High)

### 5. Fortress
- **Resource Path**: [fortress.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/fortress.tres)
- **Card Properties**:
  - Type: Defense
  - Cost: 2 Energy
  - Base Value: 12
  - Target Mode: self
- **Gameplay Description Text**: "Gain 12 block and 1 dimension charge"
- **Illustration Composition**: Blueprint Draft style. A formal front-elevation architectural blueprint drawing of a double-braced timber framing structure, including dimension ticks, thin guideline dashes, and grid ticks in the corners.
- **Card Frame Layout**: Muted blue draft line borders. The top-left badge shows the cost of 2. The illustration panel contains blueprint grids. The description text is printed in a clean typewriter-style font.
- **Under-the-Hood Scaling Logic**: Adds 12 block points to the player. Calls `ShiftManager.add_charge()` to generate exactly 1 dimension charge toward the dimension shift threshold.
- **Visual FX & Sounds**: Displays a massive blue blueprint grid shield overlay expanding around the player. Plays a heavy metallic locking clamp sound cue.
- **Urgency Tier**: Tier 2 (High)

### 6. Heavy Slash
- **Resource Path**: [heavy_slash.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/heavy_slash.tres)
- **Card Properties**:
  - Type: Attack
  - Cost: 2 Energy
  - Base Value: 10
  - Target Mode: single
- **Gameplay Description Text**: "Remove all target block, then deal 10 damage"
- **Illustration Composition**: Charcoal Pencil style. A massive vertical slash line descending down the middle of the frame, splitting a stone block into two halves. Dust clouds are drawn as stylized pixel clumps at the base.
- **Card Frame Layout**: Sienna pencil border. The top-left cost badge shows 2. The illustration window features high-contrast black and white pixel strokes. The description text is bolded.
- **Under-the-Hood Scaling Logic**: Calls `clear_block()` on the target first to strip all armor points, then applies 10 damage, scaled by any active damage multipliers (Confidence or Courage).
- **Visual FX & Sounds**: Spawns `slash_impact` scaled to 1.5x size on the target, followed by a screen-shake of 5 pixels for 0.25 seconds. Plays a heavy crashing metal sound.
- **Urgency Tier**: Tier 2 (High)

### 7. Counter Stance
- **Resource Path**: [counter_stance.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/counter_stance.tres)
- **Card Properties**:
  - Type: Defense
  - Cost: 1 Energy
  - Base Value: 6
  - Target Mode: single
- **Gameplay Description Text**: "Gain 6 block. Deal 4 fixed damage back to the attacker."
- **Illustration Composition**: Blueprint Draft style. A detailed schematic drawing of a mechanical spring-loaded recoil gear, showing teeth notches, center axis lines, and tension arrow annotations.
- **Card Frame Layout**: Muted blue draft line borders. Cost badge shows 1. Illustration window is detailed with gear schematics. The description text is aligned at the bottom.
- **Under-the-Hood Scaling Logic**: Player gains 6 block points. Target enemy receives 4 fixed damage points that bypass damage multipliers (Confidence and Courage) since it is reactive damage.
- **Visual FX & Sounds**: Spawns `spark_recoil` particles at the target node. Plays a mechanical gear-spring clicking sound cue.
- **Urgency Tier**: Tier 2 (High)

### 8. Thunder
- **Resource Path**: [thunder.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/thunder.tres)
- **Card Properties**:
  - Type: Attack
  - Cost: 1 Energy
  - Base Value: 4
  - Target Mode: single
- **Gameplay Description Text**: "Deal 4 damage and gain 2 dimension charges"
- **Illustration Composition**: Graphite Scribble style. A dramatic high-voltage jagged lightning bolt striking down onto a flat horizontal landscape line, with the sky filled with dense graphite pencil shading blocks.
- **Card Frame Layout**: High-contrast slate and yellow border. Cost badge shows 1. The illustration contains vertical vector bolts. Description text sits at the bottom.
- **Under-the-Hood Scaling Logic**: Deals 4 base damage (scaled by player damage multipliers). Calls `ShiftManager.add_charge()` twice to increment the dimension shift gauge by 2 charges.
- **Visual FX & Sounds**: Spawns a vertical `lightning_strike` FX hitting the target. Plays a sharp thunderclap crackle sound.
- **Urgency Tier**: Tier 2 (High)

---

## 8. UI, Dialogue, and HUD Elements

All UI elements must be designed with 9-patch scaling sliced border margins to scale cleanly to different screen sizes without stretching corner assets.

### 1. Dialogue TextBox and Badges
- **`textbox_bg`** (Base Dimensions: 700 x 110 pixels)
  - **Slicing Margins**: 8 pixels border margin for all sides (top, bottom, left, right).
  - **Dream Style**: Warm parchment paper texture with a soft brown hand-drawn border. Modulate set to `Color(0.96, 0.95, 0.92, 0.65)`.
  - **Reality Style**: Semi-transparent dark slate grey glass texture with a thin white border. Modulate set to `Color(0.06, 0.08, 0.12, 0.5)`.
  - **Urgency Tier**: Tier 1 (Critical)
- **`textbox_speaker_badge`** (Base Dimensions: 100 x 22 pixels)
  - **Slicing Margins**: 4 pixels border margin.
  - **Description**: Sits docked above the dialogue panel. Displays the active speaker name in a colored box matching the dimension theme (brick red for dream, silver-grey for reality).
  - **Urgency Tier**: Tier 1 (Critical)
- **`textbox_continue_arrow`** (Base Dimensions: 12 x 12 pixels)
  - **Description**: A pixel-art upside-down triangle indicator positioned in the lower-right margin of the textbox. Pulses using a sine-wave modulate curve between alpha 0.2 and 1.0 when text typewriter display is complete.
  - **Urgency Tier**: Tier 1 (Critical)

### 2. Main Menu and Panels
- **`main_menu_bg`** (Base Dimensions: 512 x 208 pixels)
  - **Description**: The background for the starting screen. Features a high-contrast half-sketch of Hilbert's face on one side and a stylized title logo on the other.
  - **Urgency Tier**: Tier 1 (Critical)
- **`settings_menu_panel`** (Base Dimensions: 200 x 120 pixels)
  - **Slicing Margins**: 6 pixels border margin.
  - **Description**: A centered overlay panel for volume sliders, resolution settings, and the exit button. Uses standard 9-patch scaling.
  - **Urgency Tier**: Tier 2 (High)
- **`booklet_layout_panel`** (Base Dimensions: 480 x 180 pixels)
  - **Slicing Margins**: 10 pixels border margin.
  - **Description**: The master container window for the Booklet UI, allowing players to view the current cards in their deck. Warm beige in dream state, slate outline in reality.
  - **Urgency Tier**: Tier 2 (High)

### 3. Combat HUD and Indicators
- **`hud_stats_box`** (Base Dimensions: 160 x 50 pixels)
  - **Slicing Margins**: 6 pixels border margin.
  - **Description**: Status frames placed directly under the player and enemy combat sprites. Displays character names, current HP progress bar, block points, and active status buffs.
  - **Urgency Tier**: Tier 1 (Critical)
- **`card_template`** (Base Dimensions: 140 x 200 pixels)
  - **Slicing Margins**: 12 pixels border margin.
  - **Description**: The paper card frame. Contains a central illustration box (96x64), a title banner at the top, and a card description slot at the bottom.
  - **Urgency Tier**: Tier 1 (Critical)
- **`energy_orb`** (Base Dimensions: 48 x 48 pixels)
  - **Description**: Circular clockwork copper gear indicator in the lower-left, representing current action points (combat energy).
  - **Urgency Tier**: Tier 1 (Critical)
- **`block_icon`** (Base Dimensions: 24 x 24 pixels)
  - **Description**: Shield vector icon displayed next to the HP bar, displaying active armor points.
  - **Urgency Tier**: Tier 1 (Critical)
- **`targeting_arrow`** (Base Dimensions: 32 x 32 pixels)
  - **Description**: A bouncy hand-drawn orange vector arrow pointing to the selected enemy target during card drag operations.
  - **Urgency Tier**: Tier 1 (Critical)
- **`draw_pile_icon`** (Base Dimensions: 48 x 48 pixels)
  - **Description**: A mini stack of drawing sheets on the lower-left showing remaining cards in deck.
  - **Urgency Tier**: Tier 1 (Critical)
- **`discard_pile_icon`** (Base Dimensions: 48 x 48 pixels)
  - **Description**: A messy pile of crumpled drawing paper sheets on the lower-right showing cards in the discard pile.
  - **Urgency Tier**: Tier 1 (Critical)
- **`end_turn_btn`** (Base Dimensions: 96 x 32 pixels)
  - **Slicing Margins**: 4 pixels border margin.
  - **Description**: Hand-drawn paper button to end the current turn.
  - **Urgency Tier**: Tier 1 (Critical)
- **`shift_btn`** (Base Dimensions: 80 x 32 pixels)
  - **Slicing Margins**: 4 pixels border margin.
  - **Description**: Double-arrow button to trigger a manual dimension shift.
  - **Urgency Tier**: Tier 2 (High)
- **`reroll_btn`** (Base Dimensions: 80 x 32 pixels)
  - **Slicing Margins**: 4 pixels border margin.
  - **Description**: Circular arrow button to reroll draft card selections.
  - **Urgency Tier**: Tier 2 (High)
- **`turn_banner`** (Base Dimensions: 400 x 80 pixels)
  - **Description**: Large overlay text reading Player Turn or Enemy Turn appearing at the start of a combat turn.
  - **Urgency Tier**: Tier 2 (High)
- **`enemy_intent_icons`** (Base Dimensions: 16 x 16 pixels per icon)
  - **Description**: Small floating icons indicating enemy actions for the next turn. Consists of a red crosshair (Attack), grey shield (Defend), and gear spiral (Special action).
  - **Urgency Tier**: Tier 2 (High)
- **`hp_bar_under` / `hp_bar_progress`** (Base Dimensions: 64 x 8 pixels)
  - **Description**: HP status bars. The progress bar displays a green fill. A secondary dark red bar sits underneath and slowly slides down to create a visual catchup lag when damage is resolved.
  - **Urgency Tier**: Tier 1 (Critical)
- **`shield_bar_overlay`** (Base Dimensions: 64 x 8 pixels)
  - **Description**: A blue shield indicator bar overlaid directly on top of the HP progress bar, showing active block points.
  - **Urgency Tier**: Tier 1 (Critical)
- **`dim_shift_gauge_bar`** (Base Dimensions: 120 x 16 pixels)
  - **Description**: Copper gauge containing glowing indicator segments representing current dimension charges.
  - **Urgency Tier**: Tier 2 (High)
- **`victory_defeat_banner`** (Base Dimensions: 240 x 48 pixels)
  - **Description**: Large banner that slides across the screen when combat ends. A warm cream scroll for victory, a cold grey cracked slate plaque for defeat.
  - **Urgency Tier**: Tier 1 (Critical)
- **`sketch_transition_mask`** (Base Dimensions: 512 x 208 pixels)
  - **Description**: A full-screen black and white transition mask depicting vertical pencil scribble smudges. Used in shaders to wipe between dream and reality environments during a dimension shift.
  - **Urgency Tier**: Tier 2 (High)

---

## 9. Combat Visual Particle Effects (FX)

Visual effects spawned on top of characters/enemies when cards are played or damage is resolved. Drawn as sprite sheet frame animations with transparent backgrounds.

| FX Asset Name | Dimensions | Frame Count | Loop | Description | Urgency Tier |
|---|---|---|---|---|---|
| `slash_impact` | 64 x 64 | 5 frames | No | Sharp white diagonal cut line appearing and dissolving. | Tier 1 (Tutorial Combat) |
| `shield_flash` | 64 x 64 | 4 frames | No | Semi-translucent sienna shield contour expanding slightly. | Tier 1 (Combat Feedback) |
| `double_slash_impact`| 64 x 64 | 8 frames | No | Two quick crossing slash vectors flashing in sequence. | Tier 2 (Combat Feedback) |
| `spark_recoil` | 48 x 48 | 5 frames | No | Small explosion sparks flying outward in sharp angles. | Tier 2 (Combat Feedback) |
| `fireball_impact` | 96 x 96 | 10 frames | No | Fireball expanding into a smoky pixel cloud and vanishing. | Tier 2 (Combat Feedback) |
| `lightning_strike` | 64 x 128 | 8 frames | No | Electrical branch flashing down from top of screen to ground. | Tier 2 (Combat Feedback) |

---

## 10. Narrative Cutscene Illustrations

Static, full-screen retro pixel artworks (512 x 208 pixels) displaying during cutscenes and endings. To preserve memory and asset consistency, they share the exact height (208px) of exploration environments, matching the viewports without visual stretching.

1. `dream_ending_illustration` (Urgency Tier: Tier 3):
   - **Composition**: Hilbert standing in a bright sienna/beige field under a sun gear. n.n. is perched on his shoulder, propellor spinning.
   - **Details**: Character details are simplified into clean black pencil strokes.
   - **Dimensions**: 512 x 208 pixels.
2. `wake_ending_illustration` (Urgency Tier: Tier 3):
   - **Composition**: A close-up of Hilbert's open hand. The metal form of n.n. lies rusted and cracked, crumbling into red dust.
   - **Details**: Background is a dark slate void with tiny floating grey motes.
   - **Dimensions**: 512 x 208 pixels.
3. `accident_memory_illustration` (Urgency Tier: Tier 4):
   - **Composition**: Rain-slicked road at night. The high-contrast glare of vehicle headlights is reflected in the water, cast against dark silhouettes.
   - **Details**: Monochromatic grey/blue tones with single desaturated amber accents.
   - **Dimensions**: 512 x 208 pixels.
