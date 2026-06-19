extends Node
# Autoload singleton representing the Global Event Bus.
# This facilitates decoupled communication between systems (e.g., UI, levels, combat, singletons).

# Narrative & Dialogue Signals
signal dialogue_started(node_id: String)
signal dialogue_text_updated(text: String, options: Array)
signal dialogue_option_selected(option_idx: int)
signal dialogue_finished()

# Interaction Signals
signal player_interacted(interaction_id: String)

# Combat & Deckbuilder Signals
signal card_drawn_to_ui(card_data: Resource)
signal ui_charge_updated(new_charge: int)
signal lock_player_ui()
signal unlock_player_ui()
signal combat_started()
signal combat_ended(victory: bool)

# Dimension Shifting Signals
signal dimension_shifted(target_dimension: String)
signal fragment_used(problem_id: String)

# Audio and Visual Effects Signals
signal play_sound(sound_name: String)
signal trigger_visual_effect(effect_name: String)
