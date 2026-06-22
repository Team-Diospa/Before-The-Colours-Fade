# Combat Mechanics and Narrative Integration Specification

This document details the logical combat engine of the game and explains how the mechanics align with the narrative structure, script progression, and game design document (GDD) guidelines.

---

## 1. Core Combat Engine and Logical Mechanics

The combat system is a turn-based deckbuilder executed via a Finite State Machine (FSM) in [CombatManager.gd](file:///d:/Codes/Before-The-Colours-Fade/scenes/combat/CombatManager.gd).

```
         +---------------------------------------+
         |                 INIT                  |
         +-------------------+-------------------+
                             |
                             v
         +-------------------+-------------------+
         |           PLAYER_START                |
         |  - Draw Hand                          |
         |  - Reset Energy & Block               |
         |  - Display Enemy Intent               |
         +-------------------+-------------------+
                             |
                             v
         +-------------------+-------------------+
  +----->|           PLAYER_ACTION               |
  |      |  - Play, Reroll, Retain, or Shift     |
  |      +-------------------+-------------------+
  |                          |
  |                          v (End Turn Pressed)
  |      +-------------------+-------------------+
  |      |            PLAYER_END                 |
  |      |  - Discard Hand                       |
  |      |  - Resolve End-of-Turn Statuses       |
  |      +-------------------+-------------------+
  |                          |
  |                          v
  |      +-------------------+-------------------+
  |      |            ENEMY_TURN                 |
  |      |  - Execute Intent                     |
  |      |  - Clear Enemy Block                  |
  |      +-------------------+-------------------+
  |                          |
  |                          +------------------------+
  |                          |                        |
  |                          v (Player Alive)         v (Player Dead)
  +--------------------------+                   +----+----+
                                                 | DEFEAT  |
                                                 +---------+
```

### A. Turn Lifecycle and States
- **INIT**: Allocates player decks, parses the current enemy or wave database, and prepares dynamic UI hooks.
- **PLAYER_START**:
  - Resets player energy to `MAX_ENERGY` (3).
  - Triggers the draw phase. By default, draws 5 cards from the draw pile. If the draw pile is empty, the discard pile is shuffled into the draw pile.
  - Clears player block (unless a retention modifier is active).
  - Evaluates and displays the enemy intent for the upcoming turn.
- **PLAYER_ACTION**: The active window where the player interacts with the interface:
  - Dragging or playing cards to execute resources.
  - Activating the once-per-round Reroll or Retain helpers.
  - Executing a Dimension Shift when gauge parameters are satisfied.
- **PLAYER_END**: Discards remaining unplayed cards in the hand (excluding retained cards) to the discard pile, resolves poison/burn ticks, and switches to the enemy phase.
- **ENEMY_TURN**: Executes the pre-rendered enemy action (Attack, Defend, or Special), clears the enemy's block, and transitions back to `PLAYER_START`.
- **VICTORY / DEFEAT**: Ends the combat instance, clean-saves parameters, and yields to the scene transition manager.

### B. Core Resources and Stats
- **HP**: Player has 50 HP. Enemies have variable health pools. Zero HP triggers DEFEAT or VICTORY states.
- **Energy**: Action points required to play cards. Represented visually as clockwork gears. Standard starting turn energy is 3. Unused energy does not carry over.
- **Block**: Flat damage absorption. Block is applied before HP calculations. Player block resets at the start of the player turn, and enemy block resets at the start of the enemy turn.
- **Cards**: Defined in [CardData.gd](file:///d:/Codes/Before-The-Colours-Fade/core/resources/CardData.gd). Cost, type, target, and damage are queried before execution.

### C. Hand Control Mechanics (Retain and Reroll)
To reduce dependency on card draw luck, the system introduces two primary hand modifiers:
- **Retain Cards**: Available once per round. When clicked, the player enters Retain Mode. Clicking a card in hand tags it. When the turn ends, the tagged card is preserved in the hand instead of being moved to the discard pile.
- **Reroll Cards**: Available once per round. Allows the player to select a card in hand and swap it with a newly drawn card from the draw pile, immediately cycling unusable actions.

---

## 2. The Dimension Shift Loop

The core progression mechanic connects the Child Dream World and the Reality World mid-battle.

```
+--------------------------------------------------------+
|                   CHILD DREAM WORLD                    |
|  - Deckbuilder combat                                  |
|  - Play cards to generate shift charges                |
+---------------------------+----------------------------+
                            |
                            v (Shift Button Pressed)
+---------------------------+----------------------------+
|                     REALITY WORLD                      |
|  - Time is frozen mid-quiz / mid-class                 |
|  - Use Dream Fragments on real-world stressors         |
|  - Obtain active buffs (Confidence, Courage)           |
+---------------------------+----------------------------+
                            |
                            v (Return Shift)
+---------------------------+----------------------------+
|                   CHILD DREAM WORLD                    |
|  - Resume deckbuilder combat                           |
|  - Apply active buffs to defeat high-defense bosses    |
+--------------------------------------------------------+
```

### A. Charge Generation
- Normal combat cards generate shift charges upon resolution (e.g., standard attacks generate 1 charge, specialized cards like Fortress generate 1 charge, and Thunder generates 2 charges).
- The shift gauge requires 3 charges to activate the Dimension Shift.

### B. Warping Logic
- When the shift button is pressed at full charge:
  - The combat state (player HP, hand cards, draw pile, discard pile, enemy HP, wave index, and status flags) is serialized and cached inside [ShiftManager.gd](file:///d:/Codes/Before-The-Colours-Fade/core/singletons/ShiftManager.gd).
  - The scene transitions back to the corresponding Reality World scene (e.g., the Classroom).
  - In Reality, time is paused. Non-player characters are frozen in place. A monochromatic filter is applied to the screen.

### C. Reality Interaction and Buff Loop
- In the Reality scene, the player interacts with physical stressors (e.g., the quiz paper, the blackboard, or classmate avatars).
- The player spends **Dream Fragments** (dropped by defeated dream minions) to interact with these stressors.
- Resolving a stressor grants a specific reality buff (written to [GlobalState.gd](file:///d:/Codes/Before-The-Colours-Fade/core/singletons/GlobalState.gd)):
  - **Confidence**: Doubles damage values (2.0x multiplier) of all Attack cards.
  - **Courage**: Increases damage values by 1.5x.
- Once the player interacts with the stressor, they execute the return shift, deserializing the cached combat scene and resuming the fight with the active multiplier.

---

## 3. Ludonarrative Integration: Projections of Dread and Paralysis

Rather than acting as simple, literal transformations of physical objects (e.g., a quiz paper physically turning into a paper monster), the combat encounters and enemies project Hilbert's internal dread, grief, and cognitive paralysis.

### A. Monsters as Projections of Internal Struggles
- **The Gear Golem (Monster Base)**: Represents Hilbert's cold, mechanical routine. After his friend's death, Hilbert operates like a machine (waking up, walking, prepping for class mechanically). The golem's clockwork motion reflects his own automated, numb existence.
- **The Exam Golem (Paper Monster)**: Represents his intellectual paralysis and cognitive overload. During the quiz, Hilbert sees only jumbled words and experiences a severe headache. The fluttering, blade-like pages of the Paper Monster represent the crushing pressure of academic expectations and his fear of mental failure.
- **The Pack Leader (Village Boss)**: Represents the burning guilt, self-blame, and anger surrounding his friend's fatal accident. The burning village represents his internal world catching fire under the weight of unresolved trauma.

### B. The Combat Loop as a Reflector of Hilbert's Behavior
- **Passive Numbness vs. Active Resolve**: 
  - Hilbert's real-world behavior is characterized by numbness and avoidance (limping, monotonic responses, staring blankly at the floor). In combat, playing standard `Strike` and `Defend` cards reflects this safe, mechanical routine. 
  - Because he is merely going through the motions, these standard actions deal zero damage to the Pack Leader boss. His passive routine is useless against his deep-seated trauma.
- **Confronting the Stressor**:
  - To break the boss's guard, Hilbert must execute a Dimension Shift. This shift is not an escape; it forces him to return to the paused real world and confront his stressors head-on.
  - By spending **Dream Fragments** (representing his childhood optimism and the creative spark he shared with his deceased friend) on the real-world stressor (the quiz paper, his classmates, the environment), Hilbert breaks his numbness.
  - Acknowledging and facing his anxiety grants him **Confidence** (doubling attack damage) or **Courage**. 
  - Returning to the dream, his cards are no longer automated routines. They represent active, emotional resolve, allowing him to pierce the boss's immunity and conquer his dread.

---

## 4. Scientific Alignment with Theoretical Story Structure

The combat and shifting systems are designed around the psychological and semiotic principles detailed in [story_structure.md](file:///d:/Codes/Before-The-Colours-Fade/docs/story_structure.md).

### A. Loewenstein's Information-Gap and the Zeigarnik Effect
- **Unresolved System State**: When the player shifts from the dream back to reality, the combat scene is not resolved; it is suspended mid-turn.
- **Curiosity Anchor**: The suspended combat state creates a cognitive gap (Zeigarnik Effect). The player's mind holds the unresolved combat layout in working memory while interacting with the real world. This prevents the reality segments from feeling like boring chores and maintains tension.

### B. State-Dependent Compartmentalization
- **Mental Boundary Representation**: Under stress, the human mind establishes boundaries between memory networks to isolate trauma.
- **Mechanical Partitioning**: The separation of the gameplay loop into two distinct states (exploration in Reality vs. card combat in Dream) mechanically mirrors this mental compartmentalization. The player is forced to jump back and forth across these structural walls, experiencing Hilbert's cognitive fragmentation firsthand.

### C. Bateson's Double-Bind Theory (Ludic Double-Bind)
- **Friction-Driven Survival**: A double-bind is a dilemma where any choice leads to friction.
- **Mechanical Double-Bind**: The player wants to stay in the comforting, warm child dream world, but they cannot win there because the boss is immune to unbuffed damage. To survive, they are forced to return to the cold, stressful reality they are escaping. This creates a loop where mechanical optimization requires confronting real-world stressors.

### D. Bartlett's Schema Theory and Schema Disruption
- **Defamiliarizing the Mundane**: In the exploration state, Hilbert's brain forces anomalous details to fit comfortable schemas to avoid distress (e.g., explaining away isolation).
- **Combat Disruptions**: During combat, these everyday environments collapse. The mechanical threat of these objects disrupts Hilbert's comforting schemas, forcing him to retroactively reconstruct a new mental framework to understand the trauma of his past.
