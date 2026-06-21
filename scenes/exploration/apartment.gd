extends Node2D
# Level script for the Apartment scene (S_apt).
# Guided objective flow: wake_up -> bed -> shower -> exit
# Full narrative sourced verbatim from docs/srcipt story.md and docs/script alur.md.
# RATIONALE: The opening scene is the entire emotional foundation.
# Every line matters. Do not compress.

@onready var CanvasModulateNode = $CanvasModulate
@onready var PlayerNode = $Player

# Room atmosphere palette from script alur.md:
# "Awalnya hawa cerah bersinar (akibat cahaya matahari),
#  lalu hawa menjadi gelap, sepi, busuk (setelah MC menutup jendela)."
const COLOR_MORNING    = Color(1.0, 0.95, 0.88, 1.0) # Warm morning sun
const COLOR_DEPRESSION = Color(0.28, 0.28, 0.38, 1.0) # Cold, dark, stale

# Objective gating.
# "wake_up"  -> opening narration only; all interactables locked
# "bed"      -> only Bed is interactive
# "shower"   -> Shower, Guitar, Desk, Wardrobe, Kitchen, Window, Papers unlock
# "exit"     -> everything free; exit door unlocks
var current_objective: String = "wake_up"

# Legacy flag used by exit door check.
var has_showered: bool = false

# ============================================================
# OPENING NARRATION  (20 beats, full script coverage)
# Source: srcipt story.md lines 17-39 and script alur.md
# "Alarm buzzing like a bee in the field... He woke up from
# his slumber, reluctantly answering the morning call."
# ============================================================
var opening_narration: Dictionary = {
	"start": {
		# Source: "Kring! Kring! ... Tap"
		"text": "Kring. Kring.",
		"next": "open_2"
	},
	"open_2": {
		"text": "Kring. Kring.",
		"next": "open_3"
	},
	"open_3": {
		"text": "Tap.",
		"next": "open_4"
	},
	"open_4": {
		# Source: "Alarm buzzing like a bee in the field, annoying everyone asleep.
		# Morning answers the call again as if the night is tired of watching over this world."
		"text": "Alarm buzzing like a bee in a field, annoying everyone still asleep. Morning answers the call again, as if the night is tired of watching over this world.",
		"next": "open_5"
	},
	"open_5": {
		# Source: "He woke up from his slumber, reluctantly answering the morning call."
		"text": "He woke from his slumber, reluctantly answering the morning call.",
		"next": "open_6"
	},
	"open_6": {
		# Source: "The light shines brightly, lighting up his room, but even then the coldness
		# and darkness of the world still wins over those warm and blinding light."
		"text": "The light shines brightly, filling his room. But even then, the coldness and the darkness of the world still wins over those warm and blinding rays.",
		"next": "open_7"
	},
	"open_7": {
		# Source: "He sits on his small creaking bed, staring at those dust covered floor,
		# 'i'll clean later' he murmured."
		# RATIONALE: Disable fullscreen cutscene overlay here to reveal the morning room transition.
		"text": "He sits on his small creaking bed, staring at the dust-covered floor.",
		"fullscreen": false,
		"next": "open_8"
	},
	"open_8": {
		"speaker": "Hilbert",
		"text": "I'll clean it later.",
		"next": "open_9"
	},
	"open_9": {
		# Source: "He looks up the leaking ceiling, water dripping down to the bucket
		# he puts down the night before, 'it's almost full, i'll change it later'."
		"text": "He looks up at the leaking ceiling. A bucket sits below it, placed there the night before. Almost full.",
		"next": "open_10"
	},
	"open_10": {
		"speaker": "Hilbert",
		"text": "I'll change it later.",
		# RATIONALE: Bypass redundant room summaries to escalate tension immediately into the landlord's knock.
		"next": "knock_1"
	},
	"open_11": {
		# Source: "He stands up with his two weak legs, limping around the room with no purpose,
		# like an animal trapped in a cage."
		"text": "He stands on two weak legs. He limps around the room with no particular purpose, like an animal in a very small cage.",
		"next": "open_12"
	},
	"open_12": {
		# Source: "His apartment is a small box, approximately 12m2, small but cheap for his pocket.
		# It's filled with a bunch of trash, he hasn't done a lot of cleaning lately."
		"text": "The apartment is approximately twelve square metres. Small, but cheap for his pocket. It is filled with things he has not sorted through in a long time. Maybe longer.",
		"next": "open_13"
	},
	"open_13": {
		# Source: "there is also a guitar hanging on the corner of the room,
		# he hasn't played it in months."
		"text": "There is a guitar hung in the corner. He has not played it in months.",
		"next": "open_14"
	},
	"open_14": {
		# Source: "He's been living in this dump for about 1 year, ever since that-."
		"text": "He has been living in this place for about a year. Ever since that-",
		"next": "knock_1"
	},
	# ------- LANDLADY KNOCK -------
	# Source: "Knock! Knock! / 'Mr. Hickman, Mr. Hilbert Hickman, are you there?'"
	"knock_1": {
		"text": "[Knock knock knock]",
		"next": "knock_2"
	},
	"knock_2": {
		"speaker": "Landlady",
		"text": "Mr. Hickman. Mr. Hilbert Hickman. Are you there?",
		"next": "knock_3"
	},
	"knock_3": {
		# Short beat of Hilbert not immediately responding.
		"text": "The knocking is patient. Not urgent. She has knocked at this door before.",
		"next": "knock_4"
	},
	"knock_4": {
		"speaker": "Hilbert",
		"text": "Yes.",
		"next": "knock_5"
	},
	"knock_5": {
		# Source: "'Oh okay, i just want to remind you that your rent's due next week,
		# please pay it on time this time, oh and, clean your room, please.
		# We still got some complain from your neighbour, if you don't clean it,
		# i'm afraid i have to evict you.'"
		"speaker": "Landlady",
		"text": "Oh, okay. I just want to remind you that your rent is due next week. Please pay on time this time. And - clean your room. We are still getting complaints from your neighbours. If it is not cleaned, I am afraid I will have to evict you.",
		"next": "knock_6"
	},
	"knock_6": {
		# Source: "'Yes, I understand, thanks.' Said Hilbert in a monotonic tone."
		"speaker": "Hilbert",
		"text": "Yes, I understand. Thanks.",
		"next": "knock_7"
	},
	"knock_7": {
		# Source: "Footsteps fading from the door, and silence starts creeping in again."
		"text": "Footsteps fade from the other side of the door. Silence starts creeping back in.",
		"next": "knock_8"
	},
	"knock_8": {
		# Source: "Hilbert sat down again on his creaking bed. He opened his phone, nothing,
		# no notifications, no new info, just the time and a reminder that his phone storage is full."
		"text": "He sits back down on the creaking bed. He opens his phone. Nothing. No notifications, no messages. Just the time, and a notice that his storage is full.",
		"next": "knock_9"
	},
	"knock_9": {
		# Source: "He closes it back and try to lie back down on his bed, suddenly his phone is ringing.
		# He checks it again to see that it's his alarm, reminding him of the lecture he needs to attend.
		# He just remembered that today's a monday."
		"text": "He closes the phone. He tries to lie back down. The alarm goes off again immediately. He had forgotten. Today is Monday.",
		"next": "knock_10"
	},
	"knock_10": {
		# Source: "As hard as his heart rejects the calling, his body move to prepare,
		# guided by his brain to the bathroom."
		"text": "As hard as his heart rejects it, his body moves to prepare itself. Guided, mechanically, toward the day.",
		"next": ""
	}
}

# ============================================================
# BED DIALOGUE  (full branching, script-accurate)
# Source: script alur.md: "Kasur: Sleep Again? (Y/N).
# If yes: *Cutscene: Reminder Kuliah*, if no: 'Probably later.'"
# ============================================================
var bed_dialogue: Dictionary = {
	"start": {
		# RATIONALE: The opening of the interaction anchors the weight of the morning and Hilbert's reluctance.
		"text": "The blanket is still warm. Still heavy. The mattress holds the shape of eight hours of avoidance.",
		"next": "bed_choice"
	},
	"bed_choice": {
		"text": "Sleep again?",
		"options": [
			{"text": "Yes - ten more minutes", "next": "bed_yes_1"},
			{"text": "No - get up now", "next": "bed_no_1"}
		]
	},
	# --- SLEEP BRANCH (20 BEATS) ---
	# Grounded in Loewenstein's info-gaps and Bartlett's reconstructive memory of the deceased friend.
	"bed_yes_1": {
		"text": "You close your eyes. The morning light filtering through the cheap curtains turns a warm, dull orange behind your eyelids.",
		"next": "bed_yes_2"
	},
	"bed_yes_2": {
		"text": "Your phone buzzes against the mattress. A calendar alert. You do not check it. It buzzes again, then falls silent.",
		"next": "bed_yes_3"
	},
	"bed_yes_3": {
		"text": "You sink back down, letting the gravity of the mattress pull you into the soft, grey margins of a half-sleep.",
		"next": "bed_yes_4"
	},
	"bed_yes_4": {
		"text": "In the quiet, you hear the distant scratch of graphite on heavy paper. A sound you have not heard in a year.",
		"next": "bed_yes_5"
	},
	"bed_yes_5": {
		"text": "You are standing in a workshop. The air is warm, thick with the smell of dry wood shavings, machine oil, and ozone.",
		"next": "bed_yes_6"
	},
	"bed_yes_6": {
		"text": "On the workbench lies a blueprint. A mechanical bird with folding brake-wings. The pencil lines are fresh, still shiny in the light.",
		"next": "bed_yes_7"
	},
	"bed_yes_7": {
		"text": "A hand reaches into the frame, pointing at a gear ratio in the margins. The hand is steady, confident.",
		"next": "bed_yes_8"
	},
	"bed_yes_8": {
		"speaker": "Voice",
		"text": "If we convert the torque here, the wings will stabilize during descent. What do you think, Hil?",
		"next": "bed_yes_9"
	},
	"bed_yes_9": {
		"text": "You try to look up, to see his face. But your eyes refuse to focus. The features are blurred, smeared with a dark grey smudge.",
		"next": "bed_yes_10"
	},
	"bed_yes_10": {
		"text": "It is like looking at a photograph that has been rubbed raw with an eraser. The harder you stare, the more the face dissolves.",
		"next": "bed_yes_11"
	},
	"bed_yes_11": {
		"text": "You try to speak, to call his name. But your throat is filled with dry dust. No sound comes out.",
		"next": "bed_yes_12"
	},
	"bed_yes_12": {
		"speaker": "Voice",
		"text": "We need to finish the brake conversion, Hil. The professor wants it by Monday.",
		"next": "bed_yes_13"
	},
	"bed_yes_13": {
		"text": "You look down at the drawing. The lines are beginning to drift, floating off the paper like black threads in water.",
		"next": "bed_yes_14"
	},
	"bed_yes_14": {
		"text": "The workshop grows cold. The smell of oil fades, replaced by the damp, stale air of your own room.",
		"next": "bed_yes_15"
	},
	"bed_yes_15": {
		"text": "You reach out to grab the paper, but your hands are heavy, made of stone. The blueprint crumbles into grey ash under your fingers.",
		"next": "bed_yes_16"
	},
	"bed_yes_16": {
		"speaker": "Hilbert",
		"text": "Wait. Just five more minutes. We can fix the gear ratios. We can align the wings.",
		"next": "bed_yes_17"
	},
	"bed_yes_17": {
		"text": "But the voice does not answer. There is only the sound of water dripping. Plop. Plop. Plop.",
		"next": "bed_yes_18"
	},
	"bed_yes_18": {
		"text": "The ticking of the alarm clock grows louder, transforming into a metallic buzz that pierces the dream.",
		"next": "bed_yes_19"
	},
	"bed_yes_19": {
		"text": "Your eyes snap open. The ceiling leak drips directly into the plastic bucket. The clock reads 7:34.",
		"next": "bed_yes_20"
	},
	"bed_yes_20": {
		"text": "A sudden spike of panic hits your chest. You are late. The morning has already won.",
		"next": "bed_yes_sys"
	},
	"bed_yes_sys": {
		# Gameplay effects matching choice.
		"text": "[System]: Rested (+10 Max HP). Late start (-1 Energy on turn 1).",
		"next": ""
	},
	# --- GET UP BRANCH (20 BEATS) ---
	# Hilbert confronts the immediate physical weight of his environment.
	"bed_no_1": {
		"speaker": "Hilbert",
		"text": "No. Quiz today. Nine o'clock. Mechanics of Materials.",
		"next": "bed_no_2"
	},
	"bed_no_2": {
		"text": "You push the heavy blanket aside. The cold air of the room hits your bare skin, a sudden shock that makes you shiver.",
		"next": "bed_no_3"
	},
	"bed_no_3": {
		"text": "You sit on the edge of the bed. The old wooden frame groans under your shifting weight, a familiar, tired complaint.",
		"next": "bed_no_4"
	},
	"bed_no_4": {
		"text": "The room is dim, lit only by the pale light cutting through the gap in the window blinds.",
		"next": "bed_no_5"
	},
	"bed_no_5": {
		"text": "Your joints feel stiff, like ungreased gears. You rotate your ankles, listening to the faint, dry click of bone.",
		"next": "bed_no_6"
	},
	"bed_no_6": {
		"text": "You stare at the floorboards. The dust lies in thin, grey sheets, undisturbed except for the path from the bed to the door.",
		"next": "bed_no_7"
	},
	"bed_no_7": {
		"text": "A bucket sits near the desk, catching the steady drip from the ceiling water stain. Plop. Plop.",
		"next": "bed_no_8"
	},
	"bed_no_8": {
		"text": "The bucket is nearly full, a dark, stagnant circle of water reflecting the yellow ceiling.",
		"next": "bed_no_9"
	},
	"bed_no_9": {
		"text": "The rust stain on the floor beneath the bucket has grown larger over the last month, a brown ring expanding outward.",
		"next": "bed_no_10"
	},
	"bed_no_10": {
		"text": "You remember him pointing at it and laughing. 'It is a topography map of our future empire,' he had said.",
		"next": "bed_no_11"
	},
	"bed_no_11": {
		"text": "Now it is just a rust stain on cheap wood. You look away from it, focusing on your own breathing.",
		"next": "bed_no_12"
	},
	"bed_no_12": {
		"text": "Your phone sits on the desk. You check it. No notifications. Just the time, and the low storage warning.",
		"next": "bed_no_13"
	},
	"bed_no_13": {
		"text": "You think about the lecture. The formulas for bending stress, shear force, elastic deformation.",
		"next": "bed_no_14"
	},
	"bed_no_14": {
		"text": "You are supposed to know how much load a structure can bear before it collapses. You are supposed to calculate the point of failure.",
		"next": "bed_no_15"
	},
	"bed_no_15": {
		"text": "It seems ironic that you are studying the limits of materials when your own structure feels so close to breaking.",
		"next": "bed_no_16"
	},
	"bed_no_16": {
		"text": "You stand up. Your knees click, a sharp, dry sound that echoes in the quiet room.",
		"next": "bed_no_17"
	},
	"bed_no_17": {
		"text": "You balance on your two weak legs, waiting for the slight dizziness to pass as the blood leaves your head.",
		"next": "bed_no_18"
	},
	"bed_no_18": {
		"text": "The floorboards are freezing. The cold cuts through your socks, a sharp discomfort that helps clear the fog in your head.",
		"next": "bed_no_19"
	},
	"bed_no_19": {
		"text": "You take a slow, deep breath. The air is stale, smelling of old paper and dust.",
		"next": "bed_no_20"
	},
	"bed_no_20": {
		"text": "You take your first step forward, limping slightly. The morning has begun, whether you are ready or not.",
		"next": "bed_no_sys"
	},
	"bed_no_sys": {
		# Gameplay effects matching choice.
		"text": "[System]: Alert start (+1 Energy on turn 1). Exhausted (-5 Max HP).",
		"next": ""
	}
}

# ============================================================
# POST-BED LANDLORD REFLECTION
# Source: "He's been living in this dump for about 1 year, ever since that-.
# (apartment context after the landlady call)"
# ============================================================
var landlord_dialogue: Dictionary = {
	"start": {
		"text": "You have not moved the things by the stairwell. You cannot remember what is out there.",
		"next": "land_2"
	},
	"land_2": {
		# Source: "a bunch of trash... schematic... project yang belum selesai"
		"text": "Maybe the box of sketchbooks. The unfinished mechanical diagrams, the project printouts from when this apartment had two people in it and the ceiling drip felt like a shared joke rather than an accusation.",
		"next": "land_3"
	},
	"land_3": {
		"text": "You do not follow that thought further.",
		"next": ""
	}
}

# ============================================================
# DESK DIALOGUE
# Source: script alur.md: "Meja: 'Papers...Unfinished...Not Much'. Choice: Open Drawer? (Y/N)
# Drawer: 'A Picture...Not Important'"
# ============================================================
var desk_dialogue: Dictionary = {
	"start": {
		# Source verbatim adapted: "meja belajar, rata-rata berisi kertas-kertas skematik,
		# dan juga projek yang belum selesai"
		"text": "The desk is buried under the last eight months of yourself. Lecture printouts. Unwashed mugs. Old schematic paper with calculations in two different handwriting styles. A drawing notebook, face down.",
		"next": "desk_2"
	},
	"desk_2": {
		# Source: "A Picture...Not Important" (alur.md)
		"text": "And a photograph, propped against the wall. Two boys holding a small mechanical trophy. Some kind of science competition, or a bridge-building contest. You cannot recall exactly.",
		"next": "desk_choice"
	},
	"desk_choice": {
		"text": "Pick up the drawing notebook?",
		"options": [
			{"text": "Yes - take the pencil and notebook", "next": "desk_open_1"},
			{"text": "No - leave it", "next": "desk_close"}
		]
	},
	"desk_open_1": {
		"text": "The notebook smells like graphite and old paper. You open it to the first page. Solar bicycle. Propeller cart. Mechanical bird with folding brake-wings.",
		"next": "desk_open_2"
	},
	"desk_open_2": {
		# Source: "Hilbert: Why is there a grey smudge over the kid on the right?"
		# (The smudged photo is puzzle piece 2 - a clue about the missing friend)
		"speaker": "Hilbert",
		"text": "Why is there a grey smudge over the kid on the right? I must have spilled something on it.",
		"next": "desk_open_3"
	},
	"desk_open_3": {
		# The second handwriting in the margins - a planted anchor.
		"text": "The margins of the notebook are covered in a second, smaller handwriting. Gear ratios. Load calculations. A single note circled three times: 'Check the brake conversion with H.'",
		"next": "desk_open_sys"
	},
	"desk_open_sys": {
		"text": "[System]: Pencil becomes Sword (Double Strike added to deck). Notebook becomes Spellbook (Fireball added to deck).",
		"next": ""
	},
	"desk_close": {
		"text": "You leave the notebook face down on the desk. You haven't felt like drawing in a long time.",
		"next": ""
	}
}

# ============================================================
# GUITAR DIALOGUE
# Source: script alur.md: "Gitar: 'Not really in the mood to play.'"
# srcipt story.md: "there is also a guitar hanging on the corner of the room,
# he hasn't played it in months."
# ============================================================
var guitar_dialogue: Dictionary = {
	"start": {
		"text": "The guitar is leaned against the wall. Months of dust on the strings. There is a strip of tape on the headstock - the ink has faded to a grey smear. You cannot read it anymore.",
		"next": "guitar_choice"
	},
	"guitar_choice": {
		"text": "Play a chord?",
		"options": [
			{"text": "Yes - pick it up", "next": "guitar_yes_1"},
			{"text": "No - not in the mood", "next": "guitar_no"}
		]
	},
	"guitar_yes_1": {
		"text": "The strings are dusty but they hold. You play a single chord. It fills the small room in a way that feels out of proportion to its size.",
		"next": "guitar_yes_2"
	},
	"guitar_yes_2": {
		# Source: "Hilbert: Still out of tune. Someone set the fourth string to D.
		# I don't remember doing that."
		# RATIONALE: Open D is a clue - it is not a tuning Hilbert uses. The friend did.
		"speaker": "Hilbert",
		"text": "Still out of tune. Someone set the fourth string to open D. I don't remember doing that.",
		"next": "guitar_yes_3"
	},
	"guitar_yes_3": {
		"text": "Open D is not a tuning you use. But the chord sounds familiar. You must have heard it somewhere. Recently. Maybe.",
		"next": "guitar_yes_sys"
	},
	"guitar_yes_sys": {
		"text": "[System]: The sound opens something. HP fully restored. Heavy Slash and Thunder added to deck.",
		"next": ""
	},
	"guitar_no": {
		# Source alur.md: "Not really in the mood to play."
		"text": "Not really in the mood. You leave it where it is.",
		"next": ""
	}
}

# ============================================================
# SHOWER DIALOGUE  (most important - full script passage)
# Source: srcipt story.md lines 41-43:
# "While in the bathroom, some thought came in his mind, wouldn't it be nice
# to feel the silence forever, not worried about everything, finally in peace
# surrounded by darkness. But, that thought is cut off by another ring from the phone.
# ...He continues to stare, not realizing he drank the foam of his soap."
# ============================================================
var shower_dialogue: Dictionary = {
	"start": {
		# RATIONALE: Visual novel dialogue expansion (28 beats) to create atmospheric attunement (Massumi).
		"text": "A shower.",
		"next": "shower_2"
	},
	"shower_2": {
		"text": "The bathroom door creaks as you push it open. The air inside is cold and damp, smelling faintly of old grout and lime.",
		"next": "shower_3"
	},
	"shower_3": {
		"text": "You turn the shower dial. Behind the wall, the pipes screech in protest, a metal-on-metal grind that makes you wince.",
		"next": "shower_4"
	},
	"shower_4": {
		"text": "You wait. The water takes a full two minutes to heat up, running clear and freezing into the plastic drain.",
		"next": "shower_5"
	},
	"shower_5": {
		"text": "You step into the cold stream anyway. The shock is immediate, a freezing needle-prick that makes you gasp.",
		"next": "shower_6"
	},
	"shower_6": {
		"text": "The cold water runs down your back, stealing the remaining warmth from your sleep.",
		"next": "shower_7"
	},
	"shower_7": {
		"text": "Slowly, the water begins to turn lukewarm. A thin veil of steam rises, clinging to the cold tiles.",
		"next": "shower_8"
	},
	"shower_8": {
		"text": "The steam fogs up the small, square mirror above the sink, hiding your reflection behind a white mist.",
		"next": "shower_9"
	},
	"shower_9": {
		"text": "You step out of the stream for a moment and walk to the sink. You run your hand across the glass, clearing a circle.",
		"next": "shower_10"
	},
	"shower_10": {
		"text": "Your reflection looks back. Pale skin. Dark circles under your eyes. Wet hair plastered to your forehead.",
		"next": "shower_11"
	},
	"shower_11": {
		"text": "You look like a stranger. A drawing of someone you used to know, sketched with a soft graphite pencil that has begun to smudge.",
		"next": "shower_12"
	},
	"shower_12": {
		"text": "You trace your finger on the steam-covered glass. You write the letter 'H'. Then a space. Then you stop.",
		"next": "shower_13"
	},
	"shower_13": {
		"text": "You want to write his initials next to yours, like you used to do on the dusty windows of the workshop.",
		"next": "shower_14"
	},
	"shower_14": {
		"text": "But you cannot bring yourself to do it. The space remains empty. A silent gap on the glass.",
		"next": "shower_15"
	},
	"shower_15": {
		"text": "You watch the condensation collect on the letters. A single drop runs down, melting the 'H' into a long, wet streak.",
		"next": "shower_16"
	},
	"shower_16": {
		"text": "You return to the shower. The water is warmer now, but the heat feels distant, like it is warming someone else's skin.",
		"next": "shower_17"
	},
	"shower_17": {
		"text": "You stare blankly at the drain. The water swirls in a slow circle, carrying away grey suds and dust.",
		"next": "shower_18"
	},
	"shower_18": {
		# RATIONALE: Focus on physical steam blanket and sound isolation.
		# Blocks out external noises to highlight isolation without explicit suicidal thoughts.
		"text": "The steam grows thicker, wrapping around you like a heavy blanket. The sound of the rushing water blocks out the rest of the world, masking the ticking clock and the dripping ceiling.",
		"next": "shower_19"
	},
	"shower_19": {
		# RATIONALE: Physical contact with cold environment to contrast the lukewarm water.
		"text": "You press your forehead against the cold tiles, letting the stream hit the back of your neck. The water is losing its warmth, turning slowly back to lukewarm, then cold.",
		"next": "shower_20"
	},
	"shower_20": {
		# RATIONALE: Focus on spatial disorientation and mist masking clutter.
		"text": "The mist makes the boundaries of the small stall disappear. For a few seconds, there are no walls, no clutter, no books - just the white noise of water hitting plastic.",
		"next": "shower_21"
	},
	"shower_21": {
		"text": "The phone rings from the bathroom shelf, a sharp, electronic chirp that cuts through the steam. The quiz is in an hour.",
		"next": "shower_22"
	},
	"shower_22": {
		"text": "You sigh, blinking water from your eyes. You lather the soap, your movements mechanical and slow.",
		"next": "shower_23"
	},
	"shower_23": {
		"text": "You continue to stare at the wall, not realizing you have swallowed a mouthful of soap foam.",
		"next": "shower_24"
	},
	"shower_24": {
		"text": "The taste is bitter, chemical. You spit it out, but the soapy residue remains on your tongue, a sharp reminder of your distraction.",
		"next": "shower_25"
	},
	"shower_25": {
		"text": "You know you should care about the chemical taste, about your health, about the test. But the spark is simply gone.",
		"next": "shower_26"
	},
	"shower_26": {
		"text": "Standing there with a numb mind, on the edge of something you cannot name, the only thing you feel is an empty, heavy silence.",
		"next": "shower_27"
	},
	"shower_27": {
		"text": "Mechanically, you turn the dial off. The water stops. The silence that follows is louder than the shower.",
		"next": "shower_28"
	},
	"shower_28": {
		"text": "You grab your towel, holding onto whatever fractured piece of peace is still left in the damp room.",
		"next": ""
	}
}

# ============================================================
# TOILET
# Source alur.md: "Just a toilet. Nothing Much."
# ============================================================
var toilet_dialogue: Dictionary = {
	"start": {
		"text": "Just a toilet. Nothing much.",
		"next": ""
	}
}

# ============================================================
# WARDROBE
# Source: "After the shower, he wears his plain old clothes paired with his worn out jacket..."
# ============================================================
var wardrobe_dialogue: Dictionary = {
	"start": {
		"text": "Three faded shirts. A worn jacket. The same trousers from yesterday, technically clean. You grab what's familiar. Nobody will notice, or if they do, you are beyond caring.",
		"next": "ward_2"
	},
	"ward_2": {
		# Planted anchor: a green scarf that doesn't belong to Hilbert.
		"text": "On the inside hook there is a dark green scarf that is not yours. You have not looked at it directly in several weeks. You do not look at it now.",
		"next": ""
	}
}

# ============================================================
# KITCHEN
# Source: apartment description "small but cheap" / neglected
# ============================================================
var kitchen_dialogue: Dictionary = {
	"start": {
		"text": "The sink is full of unwashed mugs. You haven't cooked anything warm in months. There is still one clean fork in the drying rack, which is either an achievement or an accusation.",
		"next": "kitchen_2"
	},
	"kitchen_2": {
		"text": "You drink tap water standing at the counter. Cold and flat. It will have to do.",
		"next": ""
	}
}

# ============================================================
# WINDOW
# Source: script alur.md: "Awalnya hawa cerah bersinar (akibat cahaya matahari),
# lalu hawa menjadi gelap, sepi, busuk (setelah MC menutup jendela)."
# ============================================================
var window_dialogue: Dictionary = {
	"start": {
		"text": "Three floors below, the morning market is already in motion. Tin scraping concrete. Someone arguing about price. The light coming in at this angle is almost yellow.",
		"next": "win_2"
	},
	"win_2": {
		"text": "You used to draw this view. From memory, in lectures, in the margins of problem sets. The market, the rooftops, the way the morning light breaks across corrugated iron.",
		"next": "win_choice"
	},
	"win_choice": {
		"text": "Close the blinds?",
		"options": [
			{"text": "Yes - block out the day", "next": "win_yes"},
			{"text": "No - leave them open", "next": "win_no"}
		]
	},
	"win_yes": {
		"text": "You close the blinds. The room becomes dimmer. Quieter. You focus on your breathing, finding a fragile pocket of isolation.",
		"next": "win_yes_sys"
	},
	"win_yes_sys": {
		"text": "[System]: Closing blinds filters the distractions. (+5 starting Block on turn 1 of combat).",
		"next": ""
	},
	"win_no": {
		"text": "You leave the window open. The light is harsh and the noise is loud, but it keeps you anchored to the day.",
		"next": "win_no_sys"
	},
	"win_no_sys": {
		"text": "[System]: Remaining anchored expands your awareness. (+1 card drawn on turn 1 of combat).",
		"next": ""
	}
}

# ============================================================
# PAPERS (on the floor)
# Source: "meja belajar, rata-rata berisi kertas-kertas skematik,
# dan juga projek yang belum selesai." + the second handwriting anchor
# ============================================================
var papers_dialogue: Dictionary = {
	"start": {
		"text": "Old schematics scattered across the floor near the desk. A solar-powered bicycle. A mechanical bridge. A wind-powered generator built from tin cans.",
		"next": "pap_2"
	},
	"pap_2": {
		"text": "All of them annotated in two different handwriting styles. Yours is the larger one, blocky and precise. The smaller one is faster, looser, written in the margins like an ongoing argument.",
		"next": "pap_3"
	},
	"pap_3": {
		# Puzzle anchor: the second handwriting note - piece 1 of the mystery.
		"text": "One note in the smaller handwriting, circled three times and underlined: 'Check the brake conversion with H. Also - the fourth string is D now, try it.'",
		"next": ""
	}
}

# ============================================================
# DOOR DIALOGUE
# Source: "he heads out of the apartment." / "Loading Screen (Fade to black)"
# ============================================================
var door_dialogue: Dictionary = {
	"start": {
		# RATIONALE: Visual novel dialogue expansion (20 beats) before the final choice.
		# Establishes the dread of entering the symbolic world and registers the coping mechanism.
		"text": "The door. The heavy wood panel separates this small, quiet box from the rest of the world.",
		"next": "door_2"
	},
	"door_2": {
		"text": "You stand in front of it, your hand hovering over the metal handle. It is cold to the touch.",
		"next": "door_3"
	},
	"door_3": {
		"text": "Through the thin wood, you can hear the faint sounds of the hallway. The hum of the elevator. The distant murmur of a neighbour's television.",
		"next": "door_4"
	},
	"door_4": {
		"text": "Every step beyond this threshold requires a commitment you are not sure you can make.",
		"next": "door_5"
	},
	"door_5": {
		"text": "You think about the walk to the faculty building. The crowded sidewalks. The bright, yellow sunlight that feels too loud.",
		"next": "door_6"
	},
	"door_6": {
		"text": "The way people look at you. Or worse, the way they look away, knowing what happened but not knowing what to say.",
		"next": "door_7"
	},
	"door_7": {
		"text": "You adjust the strap of your bag. It is heavy, filled with books and drawing notebooks you have not opened in months.",
		"next": "door_8"
	},
	"door_8": {
		"text": "In the side pocket, your fingers brush against a small piece of metal. A brass gear from an old prototype.",
		"next": "door_9"
	},
	"door_9": {
		"text": "You keep it there like a lucky charm, or maybe a weight to keep you anchored to the ground.",
		"next": "door_10"
	},
	"door_10": {
		"text": "You look back at the room one last time. The unmade bed. The dusty guitar. The stack of papers on the floor.",
		"next": "door_11"
	},
	"door_11": {
		"text": "It is a mess, but it is a familiar mess. A space where you do not have to pretend to be fine.",
		"next": "door_12"
	},
	"door_12": {
		"text": "Once you open this door, you have to play the role. You have to be Hilbert Hickman, the student who is doing his best.",
		"next": "door_13"
	},
	"door_13": {
		"text": "You have to answer questions. You have to sit in the lecture hall and pretend the empty chair next to you is just a chair.",
		"next": "door_14"
	},
	"door_14": {
		"text": "You take a slow breath. Your chest feels tight, like a band of iron is wrapping around your ribs.",
		"next": "door_15"
	},
	"door_15": {
		"text": "Your breathing pattern is already starting to worsen. The air feels thin, hard to swallow.",
		"next": "door_16"
	},
	"door_16": {
		"text": "You remember his words. The voice from the dream, or maybe from a memory you have polished too many times.",
		"next": "door_17"
	},
	"door_17": {
		"speaker": "Voice",
		"text": "Living in fiction is fun, isn't it? When it's too loud, just treat it like a game. Live your life a little...",
		"next": "door_18"
	},
	"door_18": {
		"text": "Treat it like a game. A series of inputs and outputs. A quest with objectives and conditions.",
		"next": "door_19"
	},
	"door_19": {
		"text": "If you treat it like a game, the choices do not have to carry so much weight. The failures do not have to be permanent.",
		"next": "door_20"
	},
	"door_20": {
		"text": "You grip the handle. The metal is no longer cold, warmed by the sweat of your palm.",
		"next": "door_choice"
	},
	"door_choice": {
		"text": "Leave the apartment?",
		"options": [
			{"text": "Yes - go to the faculty building", "next": "exit_yes"},
			{"text": "Not yet", "next": "exit_no"}
		]
	},
	"exit_yes": {
		"text": "You step out and pull the door shut. The lock clicks. You do not look back.",
		"next": ""
	},
	"exit_no": {
		"text": "Not yet. One more moment in the familiar silence.",
		"next": ""
	}
}

var door_locked_shower: Dictionary = {
	"start": {
		"text": "You are not ready. Not yet.",
		"next": ""
	}
}

var door_locked_bed: Dictionary = {
	"start": {
		"text": "Start the morning first.",
		"next": ""
	}
}

# ============================================================
# SCENE SETUP
# ============================================================
func _ready() -> void:
	if has_node("Bed"):      $Bed.interacted.connect(_on_bed_interacted)
	if has_node("Guitar"):   $Guitar.interacted.connect(_on_guitar_interacted)
	if has_node("Desk"):     $Desk.interacted.connect(_on_desk_interacted)
	if has_node("Toilet"):   $Toilet.interacted.connect(_on_toilet_interacted)
	if has_node("Shower"):   $Shower.interacted.connect(_on_shower_interacted)
	if has_node("ExitDoor"): $ExitDoor.interacted.connect(_on_exit_door_interacted)
	if has_node("Wardrobe"): $Wardrobe.interacted.connect(_on_wardrobe_interacted)
	if has_node("Kitchen"):  $Kitchen.interacted.connect(_on_kitchen_interacted)
	if has_node("Window"):   $Window.interacted.connect(_on_window_interacted)
	if has_node("Papers"):   $Papers.interacted.connect(_on_papers_interacted)

	# RATIONALE: If we are restoring from a saved game, skip the opening narration and
	# set the correct objective state immediately to avoid repeating dialog.
	if GlobalState.has_flag("bed_slept"):
		CanvasModulateNode.color = COLOR_MORNING
		if GlobalState.has_flag("has_showered"):
			has_showered = true
			_advance_objective("exit")
			CanvasModulateNode.color = COLOR_DEPRESSION
		else:
			_advance_objective("shower")
			if GlobalState.has_flag("window_closed"):
				CanvasModulateNode.color = COLOR_DEPRESSION
	else:
		# RATIONALE: Fresh game start sets canvas to pitch black for an atmospheric narration.
		CanvasModulateNode.color = Color.BLACK
		call_deferred("_trigger_opening_narration")

func _trigger_opening_narration() -> void:
	# RATIONALE: Monitor dialogue text updates to coordinate lighting transitions during intro.
	if not EventBus.dialogue_text_updated.is_connected(_on_dialogue_text_updated):
		EventBus.dialogue_text_updated.connect(_on_dialogue_text_updated)
	# RATIONALE: Pass true to enable the visual novel style dedicated fullscreen cutscene for the opening alarm narration.
	DialogueSystem.start_dialogue(opening_narration, "start", true)
	if not EventBus.dialogue_finished.is_connected(_on_opening_narration_finished):
		EventBus.dialogue_finished.connect(_on_opening_narration_finished)

# Coordinates lighting changes during the opening narration sequence.
func _on_dialogue_text_updated(text: String, options: Array) -> void:
	if DialogueSystem.dialogue_tree == opening_narration and DialogueSystem.current_node_id == "open_6":
		# RATIONALE: Gradually fade the morning light in as the text mentions bright light filling the room.
		var tween = create_tween()
		tween.tween_property(CanvasModulateNode, "color", COLOR_MORNING, 3.5)

func _on_opening_narration_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_opening_narration_finished)
	if EventBus.dialogue_text_updated.is_connected(_on_dialogue_text_updated):
		EventBus.dialogue_text_updated.disconnect(_on_dialogue_text_updated)
	if DialogueSystem.dialogue_tree == opening_narration:
		_advance_objective("bed")

func _advance_objective(new_objective: String) -> void:
	current_objective = new_objective
	match new_objective:
		"bed":
			ExplorationHUD.set_objective("Check the bed.")
		"shower":
			ExplorationHUD.set_objective("Get ready. Use the shower.")
		"exit":
			ExplorationHUD.set_objective("Leave the apartment.")

# ============================================================
# INTERACTABLE HANDLERS
# ============================================================

func _on_bed_interacted(_id: String) -> void:
	if current_objective == "wake_up":
		return
	if GlobalState.has_flag("bed_slept"):
		DialogueSystem.start_dialogue({"start": {"text": "You've already made your choice about the bed.", "next": ""}}, "start")
		return
	# RATIONALE: Pass true to enable the visual novel style dedicated fullscreen cutscene for the bed monologue choice.
	DialogueSystem.start_dialogue(bed_dialogue, "start", true)
	if not EventBus.dialogue_finished.is_connected(_on_bed_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_bed_dialogue_finished)

func _on_bed_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_bed_dialogue_finished)
	if DialogueSystem.dialogue_tree == bed_dialogue:
		GlobalState.set_flag("bed_slept", true)
		if DialogueSystem.current_node_id == "bed_yes_sys":
			GlobalState.player_max_hp += 10
			GlobalState.player_current_hp += 10
			GlobalState.starting_energy_modifier = -1
		elif DialogueSystem.current_node_id == "bed_no_sys":
			GlobalState.player_max_hp = max(10, GlobalState.player_max_hp - 5)
			GlobalState.player_current_hp = min(GlobalState.player_current_hp, GlobalState.player_max_hp)
			GlobalState.starting_energy_modifier = 1
		call_deferred("_trigger_landlord_dialogue")

func _trigger_landlord_dialogue() -> void:
	DialogueSystem.start_dialogue(landlord_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_landlord_finished):
		EventBus.dialogue_finished.connect(_on_landlord_finished)

func _on_landlord_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_landlord_finished)
	if DialogueSystem.dialogue_tree == landlord_dialogue:
		_advance_objective("shower")

func _on_guitar_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	if GlobalState.has_flag("guitar_played"):
		DialogueSystem.start_dialogue({"start": {"text": "You don't feel like playing the guitar again.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(guitar_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_guitar_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_guitar_dialogue_finished)

func _on_guitar_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_guitar_dialogue_finished)
	if DialogueSystem.dialogue_tree == guitar_dialogue and DialogueSystem.current_node_id == "guitar_yes_sys":
		GlobalState.set_flag("guitar_played", true)
		GlobalState.player_current_hp = GlobalState.player_max_hp
		var hslash_res = load("res://data/cards/heavy_slash.tres")
		var thunder_res = load("res://data/cards/thunder.tres")
		if hslash_res and not GlobalState.master_deck.has(hslash_res):
			GlobalState.master_deck.append(hslash_res)
		if thunder_res and not GlobalState.master_deck.has(thunder_res):
			GlobalState.master_deck.append(thunder_res)

func _on_desk_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	if GlobalState.has_flag("desk_searched"):
		DialogueSystem.start_dialogue({"start": {"text": "The desk has been cleared.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(desk_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_desk_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_desk_dialogue_finished)

func _on_desk_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_desk_dialogue_finished)
	if DialogueSystem.dialogue_tree == desk_dialogue and DialogueSystem.current_node_id == "desk_open_sys":
		GlobalState.set_flag("desk_searched", true)
		var dstrike_res = load("res://data/cards/double_strike.tres")
		var fireball_res = load("res://data/cards/fireball.tres")
		if dstrike_res and not GlobalState.master_deck.has(dstrike_res):
			GlobalState.master_deck.append(dstrike_res)
		if fireball_res and not GlobalState.master_deck.has(fireball_res):
			GlobalState.master_deck.append(fireball_res)

func _on_toilet_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	DialogueSystem.start_dialogue(toilet_dialogue, "start")

func _on_shower_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	# RATIONALE: Gated shower to prevent replaying the long monologue cutscene multiple times.
	if GlobalState.has_flag("has_showered"):
		DialogueSystem.start_dialogue({"start": {"text": "You've already showered. The water has run cold.", "next": ""}}, "start")
		return
	# Shower tints the room dark as per script alur.md atmosphere note.
	var tween = create_tween()
	tween.tween_property(CanvasModulateNode, "color", COLOR_DEPRESSION, 5.0)
	has_showered = true
	GlobalState.set_flag("has_showered", true)
	# RATIONALE: Pass true to trigger the sensory-based shower monologue sequence in fullscreen cutscene mode.
	DialogueSystem.start_dialogue(shower_dialogue, "start", true)
	if not EventBus.dialogue_finished.is_connected(_on_shower_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_shower_dialogue_finished)

func _on_shower_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_shower_dialogue_finished)
	if DialogueSystem.dialogue_tree == shower_dialogue:
		_advance_objective("exit")

func _on_exit_door_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		DialogueSystem.start_dialogue(door_locked_bed, "start")
		return
	if current_objective == "shower":
		DialogueSystem.start_dialogue(door_locked_shower, "start")
		return
	# RATIONALE: If the door has already been inspected once, jump directly to the choice node to avoid re-triggering the long cutscene dialogue.
	if GlobalState.has_flag("door_inspected"):
		DialogueSystem.start_dialogue(door_dialogue, "door_choice", false)
		if not EventBus.dialogue_finished.is_connected(_on_door_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_door_dialogue_finished)
		return
		
	GlobalState.set_flag("door_inspected", true)
	# RATIONALE: Pass true to display the exit door transition dialogue in visual novel cutscene mode.
	DialogueSystem.start_dialogue(door_dialogue, "start", true)
	if not EventBus.dialogue_finished.is_connected(_on_door_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_door_dialogue_finished)

func _on_door_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_door_dialogue_finished)
	if DialogueSystem.dialogue_tree == door_dialogue and DialogueSystem.current_node_id == "exit_yes":
		SceneManager.transition_to_state("S_hall")

func _on_wardrobe_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	DialogueSystem.start_dialogue(wardrobe_dialogue, "start")

func _on_kitchen_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	DialogueSystem.start_dialogue(kitchen_dialogue, "start")

func _on_window_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	if GlobalState.has_flag("window_closed") or GlobalState.starting_draw_modifier > 0 or GlobalState.starting_block_modifier > 0:
		DialogueSystem.start_dialogue({"start": {"text": "You've already set the window for the morning.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(window_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_window_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_window_dialogue_finished)

func _on_window_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_window_dialogue_finished)
	if DialogueSystem.dialogue_tree == window_dialogue:
		if DialogueSystem.current_node_id == "win_yes_sys":
			GlobalState.set_flag("window_closed", true)
			GlobalState.starting_block_modifier += 5
			# Source alur.md: "hawa menjadi gelap, sepi, busuk (setelah MC menutup jendela)"
			var tween = create_tween()
			tween.tween_property(CanvasModulateNode, "color", COLOR_DEPRESSION, 2.5)
		elif DialogueSystem.current_node_id == "win_no_sys":
			GlobalState.set_flag("window_closed", false)
			GlobalState.starting_draw_modifier += 1
			var tween = create_tween()
			tween.tween_property(CanvasModulateNode, "color", COLOR_MORNING, 1.5)

func _on_papers_interacted(_id: String) -> void:
	if current_objective in ["wake_up", "bed"]:
		return
	DialogueSystem.start_dialogue(papers_dialogue, "start")
