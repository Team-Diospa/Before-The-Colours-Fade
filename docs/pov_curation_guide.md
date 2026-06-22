# POV Curation Guide: Indirect Emotional Storytelling

This guide details how to design dialogue, UI feedback, and combat mechanics to convey Hilbert Hickmans perspective (numbness, grief, dissociation, and anxiety) without resorting to literal exposition. Every element must show, not tell, his internal state.

---

## 1. Dialogue and Narration Curation

To convey Hilbert's grief-induced numbness and depersonalization, all text must adhere to strict structural constraints.

### A. Hilbert's Speech Patterns
- **Monotonic Brevity**: Hilbert's replies must be short, monotonic, and dry. He avoids exclamation marks, decorative adjectives, and emotional punctuation.
  - *Incorrect (Too Literal)*: "I am so stressed about this quiz, my head is spinning!"
  - *Correct (Indirect)*: "The paper is on the desk. Words are overlapping. I cannot read them."
- **Avoidance of Personal Names**: Hilbert rarely refers to others by name, nor does he say "I" unless describing a physical action. This mirrors his withdrawal from social connections.
- **Delayed Input Representation**: Before Hilbert speaks in dialogue panels, a small typewriter delay (0.4 seconds) should trigger, simulating his slow cognitive processing.

### B. Third-Person Narrative Voice (Depersonalization)
- Narration must describe Hilbert's body and surroundings as detached physical objects, reflecting dissociative depersonalization:
  - *Incorrect*: "You feel extremely sad and hollow inside."
  - *Correct*: "You look at your feet. They move forward. The door handles are cold."
- Focus on sensory details that highlight detachment: the coldness of water, the ticking of a clock, the texture of dust on a phone screen.

---

## 2. UI and Input Design as Emotional Feedback

The player must feel Hilbert's physical and mental resistance directly through the game interface.

```
+-------------------------------------------------------------+
|  REALITY EXPLORATION (Dissociation / Numb State)            |
|  - Movement Speed: Reduced to 50% (dragging feet)           |
|  - Audio: Low-pass filter (muffled, distant sounds)          |
|  - Visual: Desaturated, high-contrast monochrome            |
+-------------------------------------------------------------+
                              |
                              v (Dimension Shift)
+-------------------------------------------------------------+
|  COMBAT ACTION (Escapist Hyper-Focus)                       |
|  - UI Buttons: Quick, responsive, tactile sound cues        |
|  - Visual: Vibrant sketches, high-tempo animations          |
|  - Audio: Sharp, high-frequency canvas tearing sounds        |
+-------------------------------------------------------------+
```

### A. The Numb Input Gate
- **Movement Penalties**: In high-stress Reality sequences (such as walking down the hallway to the classroom), Hilbert's movement speed is capped at 50%. The walk cycle is heavy, representing lethargy.
- **Button Resistance**: Clicking UI options in Reality requires holding the mouse button down for 0.4 seconds (a radial fill indicator) rather than an instant click. This maps mental friction onto physical player actions.

### B. Cognitive Paralysis UI (The Quiz Scene)
- **Scrambled Glyphs**: During the quiz encounter, the UI text is not readable. The letters scramble and rotate.
- **Searching for Anchors**: The player must move the cursor to hover over words to temporarily freeze them. They must locate three stable anchor words (e.g., "Monday", "Quiz", "Clock") amidst the noise to stabilize Hilbert's mind, making the player experience the panic of a cognitive block.

### C. Sensory Deprivation (Muffled Soundscapes)
- **Reality Audio Profile**: Reality exploration uses a low-pass filter on all ambient sounds and footsteps. The world sounds distant and muffled, as if Hilbert is underwater.
- **Combat Breakthroughs**: When transitioning to the Child World, the low-pass filter cuts out instantly. Sound effects become sharp and high-contrast (e.g., card plays sound like tearing canvas sheets), emphasizing his return to focus.

---

## 3. Combat Mechanics as Psychological States

The rules of the deckbuilding combat mirror Hilbert's internal struggles.

### A. The Starting Deck (Passive Defense)
- **Hilbert's Default State**: The starting deck consists solely of [strike.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/strike.tres) and [defend.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/defend.tres). 
- **Exhaustion Design**: These cards have high energy costs relative to their output. Playing them feels unrewarding and tiring, mirroring Hilbert's automated routine of going through the motions.

### B. Active Card Behaviors as Emotional Outlets
Cards acquired later represent specific psychological defense mechanisms or breakthroughs:

- **Fortress** [fortress.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/fortress.tres)
  - *Mechanism*: High Block + 1 Dimension Charge.
  - *POV Meaning*: Hilbert retreats behind thick walls of isolation. The defensive build-up charges the Dimension Shift gauge, preparing him to escape reality.
- **Fireball** [fireball.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/fireball.tres)
  - *Mechanism*: AoE Damage + Burns enemies to force them into an Attack intent.
  - *POV Meaning*: Represents sudden, volatile anger. By attacking everything, Hilbert eliminates the enemy's defensive posture, forcing direct, painful conflict.
- **Thunder** [thunder.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/thunder.tres)
  - *Mechanism*: Minor Damage + 2 Dimension Charges.
  - *POV Meaning*: A sudden spike of panic or acceleration, rapidly forcing a shift in states to escape the threat.
- **Counter Stance** [counter_stance.tres](file:///d:/Codes/Before-The-Colours-Fade/data/cards/counter_stance.tres)
  - *Mechanism*: Block + Fixed Reaction Damage.
  - *POV Meaning*: Hilbert does not initiate aggression; he builds a wall and lets the world hurt itself against his defenses.

### C. The Shift loop (Forced Confrontation)
- **The Boss Immunity Gate**: Bosses in the Child World are immune to default cards. This represents Hilbert realizing he cannot defeat his trauma through escapist fantasies alone.
- **Confrontation Requirement**: The player is forced to shift back to Reality. Hilbert must interact with the frozen real-world stressor to collect the active multipliers. The mechanic enforces the theme: you must face the reality of your stress to find the emotional power to resolve it.

---

## 4. Exploration and Environmental Layout Design (Physicalizing Anxiety)

Level layouts are structured to physically represent Hilbert's emotional symptoms.

### A. The Apartment (Reality Pressure)
- **The Leaking Ceiling**: The bucket catching ceiling water is placed in the center of the room. It fills up slowly as the player spends time exploring. If the bucket overflows, the floor turns wet, and Hilbert's movement speed drops by another 10%. This creates a physical representation of daily maintenance pressures piling up.
- **Neglected Guitar**: Interacting with the guitar does not play music. It triggers the message: "Not really in the mood to play." The guitar acts as a silent trace of his dead creative partner.

### B. The Faculty Hallway (Agoraphobia and Distance)
- **Elongated Proportions**: The hallway is drawn with exaggerated perspective, making the classroom door appear much further away than it is. Lockers are spaced out irregularly, creating a cold, imposing industrial landscape that mirrors social anxiety and dread of arrival.
- **Fading Lights**: The hallway light bulbs flicker in rhythm with Hilbert's heartbeat sound effect. High stress levels reduce the radius of the screen-vignette light mask, closing his field of view.

### C. The Classroom (Social Rejection and Alienation)
- **Peer Positioning**: Classmates sit with their backs turned to Hilbert. 
- **The Empty Desk**: An empty desk next to Hilbert is drawn without any objects. Interacting with it yields: "Empty." This is the slot where his deceased partner once sat, serving as a constant silent reminder of his grief.

---

## 5. Non-Player Characters (NPCs) as Pressures

NPC interactions represent structural or social stressors.

### A. Depersonalization of Classmates
- **De-Naming**: Hilbert does not see classmate names. The HUD displays their badges as "Peer A" or "Peer B" rather than personal names, reflecting his social dissociation.
- **Overlapping Murmurs**: In the classroom, background audio plays muffled, overlapping whispers. If Hilbert stands near peers, the whispers grow slightly louder but remain unintelligible, mirroring the paranoia of being talked about.

### B. Authority Pressures
- **The Landlady**: Represents structural economic demands (eviction, rent). Her dialogue font size is slightly larger than Hilbert's text, representing an imposing weight.
- **The Professor**: Represents rigid academic evaluation. In the classroom, he stands behind the podium, glared forward. The blackboard behind him contains jumbled white formulas that resemble the mechanical gears of the boss, linking academic evaluation to mechanical monsters.

---

## 6. Saving, Loading, and Pausing (The Weight of Memory)

System screens are integrated into Hilbert's mental model.

### A. Saving the Game (A Moment of Reflection)
- **The Notebook**: Saving is not a generic menu option. It is represented as Hilbert sitting at his desk and writing in his notebook.
- **File Slots**: Save files are saved as "Memory Logs" containing the current stress level, date, and completed combat stage.

### B. Loading the Game (The Flashback Gate)
- **Retrieval Cues**: When loading a saved file, a brief monochromatic image of the last completed stressor flashes on screen for 1 second, accompanied by a low hum. This ensures the player immediately retrieves the correct narrative context (Tulving's context-dependent memory).

### C. Pausing the Game (Breathing Space)
- **Notebook Interface**: The pause screen resembles Hilbert's hand-drawn drafting booklet. As his stress levels rise throughout the game:
  - The menu options and background schematics appear smudged with dark graphite lines.
  - The pause menu music becomes lower in pitch, representing a slow, heavy breath.
- **The Booklet Deck Viewer**: Viewing the deck in the Booklet UI is styled as flipping through sheets of crumpled blueprints.

---

## 7. The Emotional Narrative of the Dream World (Why the Dream is Necessary)

The Dream World (Child World) is not a generic fantasy setting. It is the central narrative engine representing Hilbert's psychological survival mechanism, structured around the themes of nostalgia and longing for the past.

### A. The Necessity: The Reservoir of Shut-down Emotion
- **The Problem of Numbness**: After his friend's death, Hilbert's mind shut down all emotional processing to avoid overwhelming pain, leaving him in a grey, numb state of passive survival. In Reality, he has no drive, no spark, and no emotional energy to fight his struggles.
- **The Dream as Fuel**: The Dream World is the only place where his emotional range is preserved. Because this world was built with his deceased friend during their childhood, it contains all of Hilbert's lost optimism, color, and agency. He must go to the dream world because **it is the only place where he is still capable of feeling anything**. The dream is the emotional reservoir that fuels his fight.

### B. How He Feels: The Gilded Trap of Regression
- **Desperate Nostalgia**: In the dream, Hilbert does not experience simple happiness. He feels a desperate, clinging nostalgia. He is a 20-year-old man retreating into a 10-year-old's drawings. 
- **The Comfort and the Shame**: He feels the warmth of reconnecting with his friend's memory through n.n., but he also carries the implicit shame of regression. He knows he is hiding in a graveyard of memories, which is why the fantasy feels fragile.
- **The Intrusion of Pain**: As reality bleeds in (burning village, boss immunities), his feeling of safety collapses into panic. He is forced to realize that escapism cannot protect him: his childhood defense mechanism is breaking under the weight of his adult grief.

### C. The Narrative Role: Nostalgia as an Escape vs. Active Integration
- **Nostalgia as a Trap**: Before the accident, Hilbert was the logical mind (blueprints) and his friend was the heart (optimism/spark). Grieving his friend, Hilbert uses the Dream World to cling to the past. He wants to freeze his friend's memory in a static, childhood fantasy box where nothing changes, avoiding the cold present. However, this static nostalgia decays, turning into guilt (the burning village) because he survived while his friend died.
- **Active Integration (The Buff Loop)**: To progress, Hilbert cannot stay in the dream. The gameplay forces him to shift back to Reality to face his stressors. When he spends Dream Fragments (his memories of his friend) in the real world to get the Confidence/Courage buffs, he is **bringing his friend's creative spark back into his real life**. He is acknowledging that his friend's optimism belongs in his present actions, not just in his childhood memories.

### D. The Resolution: "Before the Colours Fade"
- **The Transition**: The goal of the game is not to live in the dream forever. The goal is to retrieve the emotional fragments of his past (optimism, agency, his friend's impact) and integrate them back into the real world.
- **Waking Up**: The title of the game refers to this transition. As Hilbert accepts his grief and faces reality, the vivid colors of the Dream World must slowly fade, and the real world must regain its color. The dream world is necessary because it serves as the bridge Hilbert must cross to wake up from his numbness and start living again.

---

## 8. The Cost of Confrontation (How Gameplay Hurts Hilbert)

Confronting trauma is painful. The gameplay does not protect Hilbert; it actively drains and hurts him. To win, the player must force Hilbert to process painful memories, physicalizing the exhaustion of recovery.

### A. Deck Pollution (The Burden of Memory Curses)
- **Trauma Infusion**: When Hilbert interacts with a real-world stressor to obtain a combat buff (Confidence or Courage), he is forced to process raw grief.
- **Curse Cards**: This action immediately injects a permanent curse card (e.g., "Grief", "Panic", or "Numbness") into his combat deck for the remainder of the encounter.
  - **Grief Card**: Costs 1 energy to play. It does nothing but consume a card slot in hand. If left in hand at the end of the turn, it deals 2 damage to Hilbert.
  - **Panic Card**: Unplayable. It reduces the player's starting turn draw count by 1 card.
  - **Numbness Card**: Unplayable. It blocks the use of the Reroll or Retain helpers while it remains in hand.
- **Mechanical Double-Bind**: The player needs the buffs to damage the immune boss, but acquiring those buffs pollutes Hilbert's mind (his deck) with cognitive clutter, making him draw fewer useful actions.

### B. Reality Decay and Vignette Constriction
- **Cumulative Stress**: Every time Hilbert shifts back to Reality mid-combat, the Reality scene becomes more hostile.
- **Visual Suffocation**: The monochrome contrast scales higher, white-washing details. The dark screen-vignette margins creep inward by 5% with each shift, representing claustrophobia and the narrowing of his sensory boundaries.
- **Audio Distortion**: Footsteps and clock ticking sound louder, sharper, and echo, while the ambient low-pass filter gets heavier, making the real world feel increasingly suffocating.

### C. The Degradation of n.n. (Projected Guilt)
- **Childhood Shield Failure**: n.n. is a projection of Hilbert's mind. As Hilbert forces the dream world to absorb his trauma, n.n. decays.
- **Glitch Behavior**: After multiple shifts, n.n.'s dialogue text starts displaying typewriter glitch markers (scrambled letters, missing words). His floating propeller animation slows down, and his portrait panel shows crack lines, forcing Hilbert to witness his childhood protector breaking under the weight of his adult grief.

---

## 9. Sensory Nostalgia and Reminiscence (Sensory Anchors)

To evoke a deep sense of reminiscence and connect the player to childhood memories, the game must prioritize concrete sensory details over abstract emotional terms.

### A. Sensory Anchors of Reality (The Cold and the Wet)
- **The Smell of Rain (Petrichor)**: In reality exploration scenes, the environment is framed by the rain outside. Hilbert notes the smell of wet asphalt creeping under the door frame or the damp scent of cold plaster walls. This connects to his childhood memories of rain-slicked backyards.
- **Pencil Lead and Graphite**: The physical tools of drawing (pencils, graphite dust, eraser crumbs) are given constant tactile focus. Hilbert describes the scratch of a lead pencil on dry paper, the silver smudge on the side of his hand, and the smell of cedar wood shavings. This grounds his current isolation in his past creative work.
- **Physical Temperature**: Sensory details emphasize cold metal handles, freezing shower water, and damp drafts, contrasting with the warm, glowing sunlight of his childhood designs.

### B. Sensory Anchors of the Dream (The Warm and the Textured)
- **Acoustic and Metallic Sounds**: The dream world features crisp, dry sounds: the snap of guitar strings, the hum of spinning brass gears, and the tearing of heavy cartridge paper. These sounds contrast with the muffled low-pass filter of reality.
- **Warm Light and Dry Grass**: Descriptions focus on the dry, warm scent of summer grass, sienna-toned paper, and the golden haze of sunshine. These serve as triggers for childhood memories, representing a safe, static past.



