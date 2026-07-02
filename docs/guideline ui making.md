# Master Blueprint: Code-Only UI/Gameplay Architecture

## 1. Project Initialization & Setup
- **Window Settings:** Set Viewport to `512x208`, Stretch Mode to `viewport`, Aspect to `keep`.
- **Global Settings:** Execute `RenderingServer.texture_set_path_filter(RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)` on startup to guarantee pixel-art crispness regardless of asset size.
- **Autoload Registry:** Create `UI_Database.gd` as an Autoload.
    - Store all asset paths in a Dictionary.
    - Preload all `.ttf` font files here.

## 2. The "Lazy" Asset Handler
- Implement the `UIBuilder` static utility class.
- **Constraint Method:** Use `TextureRect` with `EXPAND_IGNORE_SIZE` and `STRETCH_KEEP_ASPECT_CENTERED` to force massive source files (1080p) to match logical gameplay sizes (e.g., 48x48) without manual batch editing.
- **9-Patch Strategy:** Use `StyleBoxTexture` with strict `texture_margin` values (e.g., 8px) to handle all panels, forcing them to scale to `custom_minimum_size` without distorting borders.

## 3. Core UI Logic Architecture
- **Root Layering:** Use `CanvasLayer` hierarchy for sorting:
    - Layer 10: Combat HUD
    - Layer 50: Pause/Settings Menus
    - Layer 100: Transition Wipes
- **Anchoring:** Never use static `position`. Always use `set_anchors_preset()` (e.g., `PRESET_TOP_LEFT`, `PRESET_BOTTOM_RIGHT`) to ensure UI flows with window resizing.
- **Mouse Filtering:** Explicitly set `mouse_filter = Control.MOUSE_FILTER_IGNORE` on all `Container` nodes (VBox, HBox, CenterContainer) to prevent them from blocking clicks on buttons.

## 4. Combat HUD Pipeline
- **HUD Generation Script:**
    1. Spawn `CanvasLayer` -> `MarginContainer` (16px padding).
    2. Add `HBoxContainer` (Top-Left) for Player Stats.
    3. Generate `PanelContainer` using `dream_panel_9p_m8` (for Hilbert's stats).
    4. Generate `TextureProgressBar` using `prog_bar_frame` and `green_fill` for health.
    5. Add `HBoxContainer` (Bottom-Right) for Card Buttons (`End Turn`, `Shift`).
- **Data Binding:** Connect UI signals to the `GlobalState` (signals like `hp_changed`, `energy_changed`) to automate UI updates.

## 5. Transition & Shader Pipeline
- **Dimension Wipe:** Use a `ColorRect` covering the entire screen.
- **Masking:** Inject `sketch_transition_mask.png` into a `ShaderMaterial`.
- **Tweening:** Programmatically animate the `progress` shader parameter from `1.0` to `0.0` using `create_tween()` when `shift_dimension()` is called.

## 6. Deck & Combat Logic
- **Data Entry:** Create `CardData.tres` resources for every card (Attack, Defend, Special).
- **Deck Engine:** - `master_deck`: Master list of `CardData`.
    - `draw_pile`, `discard_pile`: Logic arrays for shuffling and drawing.
    - `spawn_card_ui()`: A function that accepts a `CardData` resource, generates a `TextureRect` for the card art, and sets labels using the `VT323` or `PixelifySans` fonts loaded from `UI_Database`.

## 7. Blind Workflow Checklist
- [ ] Rename all UI files to `snake_case` (remove spaces/parentheses).
- [ ] Define fixed logical sizes for every UI type (e.g., Icons=32x32, Banners=240x48).
- [ ] Create `UIBuilder` methods for `create_button`, `create_panel`, and `create_lazy_icon`.
- [ ] Connect all UI signal emissions in `GlobalState.gd` to HUD update functions.

### Essential Implementation Tips:

* **The "Proportionality" Check:** Because your target resolution is `512x208`, use this as your coordinate system. If a banner is `240px` wide, you know exactly that it will take up slightly less than half the screen width. Always calculate positions relative to this `512` base.
* **Debug Mode:** Since you are coding blindly, create a temporary "debug toggle" in your code that draws a thin red outline around your containers (`Control.draw_rect`). This will allow you to see your layout "boxes" while the game is running, ensuring they are positioned where you expect without needing the editor.
