\documentclass[11pt,a4paper,oneside]{report}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{amsmath, amssymb, amsthm}
\usepackage{geometry}
\geometry{a4paper, margin=2.0cm}
\usepackage{hyperref}
\usepackage{listings}
\usepackage{xcolor}
\usepackage{tikz}
\usetikzlibrary{automata, positioning, arrows.meta, shapes.geometric, calc, backgrounds, fit}
\usepackage{longtable}
\usepackage{booktabs}
\usepackage{caption}
\usepackage{enumitem}

% ==========================================
% LOGICAL PALETTE & LISTING CONFIGURATION
% ==========================================
\definecolor{axiomBg}{RGB}{245, 247, 250}
\definecolor{axiomBorder}{RGB}{44, 62, 80}
\definecolor{gdKeyword}{RGB}{211, 84, 0}
\definecolor{gdType}{RGB}{41, 128, 185}
\definecolor{gdString}{RGB}{39, 174, 96}
\definecolor{gdComment}{RGB}{127, 140, 141}

\lstdefinestyle{gdscript}{
    backgroundcolor=\color{axiomBg},   
    commentstyle=\color{gdComment}\itshape,
    keywordstyle=\color{gdKeyword}\bfseries,
    numberstyle=\tiny\color{gdComment},
    stringstyle=\color{gdString},
    basicstyle=\ttfamily\footnotesize,
    breakatwhitespace=false,         
    breaklines=true,                 
    captionpos=b,                    
    keepspaces=true,                 
    numbers=left,                    
    numbersep=10pt,                  
    showspaces=false,                
    showstringspaces=false,
    showtabs=false,                  
    tabsize=4,
    frame=leftline,
    rulecolor=\color{axiomBorder},
    framesep=5pt
}

\lstset{style=gdscript}

% Theorem Environments for Rigor
\newtheorem{axiom}{Axiom}[chapter]
\newtheorem{theorem}{Theorem}[chapter]
\newtheorem{definition}{Definition}[chapter]

\title{\textbf{\Huge PROYEKSI PRISMA (DIOSPA)} \\
\vspace{0.5cm}
\Large \textbf{The Master Architecture \& Algorithmic Blueprint} \\
\vspace{0.2cm}
\normalsize A Rigorous Formulation of Narrative Deckbuilding in Godot 4.x}
\author{\textbf{Directorate of Logic \& Systems Engineering}}
\date{\today}

\begin{document}

\maketitle

\begin{abstract}
This document outlines the absolute systemic foundation for the game "DIOSPA", a Narrative Turn-Based Deckbuilder. The core mechanic necessitates a continuous transition between a grim reality and a vibrant inner childhood dream. By strictly adhering to reductionist programming principles, we decompose the narrative environments (Apartment, Hallway, Classroom) and the Deckbuilder Combat into discrete Finite State Machines (FSMs) and Directed Acyclic Graphs (DAGs). This blueprint eliminates black-box dependencies, ensuring every state change, from drawing a card to shifting dimensions, is mathematically proven and structurally sound within the Godot 4.x node topology.
\end{abstract}

\tableofcontents
\newpage

% ==========================================
% CHAPTER 1: TOPOLOGICAL AXIOMS
% ==========================================
\chapter{Topological Axioms \& Memory Management}

A video game is fundamentally a manipulation of memory states over time $\Delta t$. In DIOSPA, the player must seamlessly traverse between the Reality World ($\mathcal{R}$) and the Child World ($\mathcal{C}$). If the memory of $\mathcal{R}$ is destroyed when loading $\mathcal{C}$, the game's logical continuity collapses.

\section{Axiom of Persistent State}
\begin{axiom}[The Autoload Invariance]
Any variable necessary for mapping the player's progress across distinct scene loads must reside in a domain invariant to the `get_tree().change_scene_to_file()` function.
\end{axiom}

To satisfy this, we initialize a strict Global Singleton (Autoload) named \texttt{GlobalState.gd}.

\begin{lstlisting}[language=python, caption=Deterministic Global Memory Allocation]
extends Node
# Autoload: GlobalState

# Narrative Flags (Boolean Matrix)
var narrative_flags: Dictionary = {
    "alarm_disabled": false,
    "rent_reminder_heard": false,
    "first_dimension_shift_complete": false,
    "quiz_started": false
}

# Combat Variables Persistence
var player_max_hp: int = 50
var player_current_hp: int = 50
var acquired_fragments: int = 0
var dimension_charge: int = 0
const MAX_CHARGE: int = 3 # Derived from GDD 

# Deck Persistence
var master_deck: Array[Resource] = []

func has_flag(flag_name: String) -> bool:
    return narrative_flags.get(flag_name, false)

func set_flag(flag_name: String, value: bool) -> void:
    narrative_flags[flag_name] = value
\end{lstlisting}

\section{Directory Geometry}
A chaotic directory structure introduces entropy. The repository must be strictly partitioned based on functional domains.

\begin{lstlisting}[language=bash, caption=Strict Godot File Topology]
res://
|-- core/
|   |-- singletons/          (GlobalState.gd, EventBus.gd)
|   |-- resources/           (CardBase.gd, EnemyBase.gd)
|   |-- components/          (HitboxComponent.tscn, HealthComponent.tscn)
|-- data/
|   |-- cards/               (.tres files defining Strike, Defend, etc.)
|   |-- dialogue/            (.json files mapping DAG dialogue trees)
|-- scenes/
|   |-- exploration/
|   |   |-- apartment.tscn   # Hilbert's 12m2 room 
|   |   |-- hallway.tscn     # Faculty building 
|   |   |-- classroom.tscn   # Quiz location 
|   |-- combat/
|   |   |-- child_world_arena.tscn
|-- actors/
|   |-- hilbert/             # Sprite with green vest [image_1]
|   |-- enemies/             # Paper boss, Castle boss 
\end{lstlisting}

\newpage

% ==========================================
% CHAPTER 2: EXPLORATION \& INTERACTION KINEMATICS
% ==========================================
\chapter{Exploration Kinematics \& Interaction Graphs}

The Reality World ($\mathcal{R}$) is characterized by a muted, cold color palette and restricted movement. Hilbert Hickman's traversal through his apartment and the university must reflect his psychological burden.

\section{The Player Automaton}
Hilbert is a 2D Kinematic body. We define his velocity vector $\vec{v} = (v_x, v_y)$. Since this is a side-scrolling exploration view, $v_y = 0$ unless gravity is applied.

\begin{lstlisting}[language=python, caption=Hilbert's Locomotion Engine]
extends CharacterBody2D
class_name ExplorationPlayer

const WALK_SPEED: float = 120.0 # Slow, burdened movement
@onready var sprite: Sprite2D = $Sprite2D # Mapped to Green Vest Sprite 

func _physics_process(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    
    if direction:
        velocity.x = direction * WALK_SPEED
        sprite.flip_h = direction < 0
    else:
        # Strict linear interpolation to zero to simulate dragging feet
        velocity.x = move_toward(velocity.x, 0, WALK_SPEED * delta * 5.0)

    move_and_slide()
\end{lstlisting}

\section{Euclidean Interaction Resolution}
To interact with objects (e.g., the Desk, the Guitar, the Bed), we reject continuous polling of Euclidean distances $d(p_1, p_2) = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2}$. Instead, we utilize Godot's \texttt{Area2D} signal architecture to generate an interrupt when bounding boxes intersect.

\begin{lstlisting}[language=python, caption=Deterministic Interaction Component]
extends Area2D
class_name Interactable

@export var interaction_id: String
signal interacted(id)

var is_player_near: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
    if is_player_near and event.is_action_pressed("interact"):
        interacted.emit(interaction_id)
        # Suppress input propagation
        get_viewport().set_input_as_handled() 

func _on_body_entered(body: Node2D) -> void:
    if body is ExplorationPlayer:
        is_player_near = true
        # Optional: Show UI prompt here

func _on_body_exited(body: Node2D) -> void:
    if body is ExplorationPlayer:
        is_player_near = false
\end{lstlisting}

\section{Mapping the Apartment Geometry}
Based on the visual blueprint of the apartment, we must structure the \texttt{apartment.tscn} logically from left to right.
\begin{enumerate}
    \item \textbf{Bed ($x = 0$):} Interaction triggers "Sleep Again? (Y/N)".
    \item \textbf{Wardrobe \& Guitar ($x = 150$):} Interaction triggers "Not really in the mood to play.".
    \item \textbf{Desk \& Laptop ($x = 300$):} Interaction triggers "Papers... Unfinished.".
    \item \textbf{Kitchen ($x = 500$):} Boundary wall.
\end{enumerate}

\newpage

% ==========================================
% CHAPTER 3: THE DIMENSION SHIFT MAPPING
% ==========================================
\chapter{The Dimension Shift Mapping}

The Dimension Shift $T: \mathcal{R} \to \mathcal{C}$ is the core mechanical bridge. It is triggered under two conditions: passively via narrative (e.g., the panic attack in the hallway), and actively during combat when the Shift Charge $C \ge 3$.

\section{The Charge Calculus}
During combat in $\mathcal{C}$, dealing damage accumulates charge $C$.
$$ C_{n+1} = \min(C_n + 1, C_{max}) $$
Where $C_{max} = 3$.

\begin{lstlisting}[language=python, caption=Active Dimension Shift Logic]
extends Node
class_name ShiftManager

signal dimension_shifted(target_dimension: String)

func add_charge() -> void:
    if GlobalState.dimension_charge < GlobalState.MAX_CHARGE:
        GlobalState.dimension_charge += 1
        EventBus.emit("ui_charge_updated", GlobalState.dimension_charge)

func attempt_shift_to_reality() -> void:
    if GlobalState.dimension_charge >= GlobalState.MAX_CHARGE:
        # 1. Serialize Current Combat State
        CombatSerializer.cache_combat_state()
        
        # 2. Reset Charge
        GlobalState.dimension_charge = 0
        
        # 3. Execute Scene Translation
        get_tree().change_scene_to_file("res://scenes/exploration/classroom.tscn")
    else:
        print("Shift denied. Mathematical threshold not met.")
\end{lstlisting}

\section{Semantic Translation Matrices}
The GDD explicitly requires Reality items to transform into Child World items. We encode this mathematically as a static Dictionary hash-map.

\begin{lstlisting}[language=python, caption=Semantic Bi-Directional Mapping]
class_name SemanticMatrix

const OBJECT_MAP: Dictionary = {
    "Pensil": "Sword",
    "Penghapus": "Shield",
    "Buku": "Spellbook"
} 

const EMOTION_MAP: Dictionary = {
    "Fear": "Courage",
    "Doubt": "Determination",
    "Insecurity": "Confidence",
    "Despair": "Hope",
    "Laziness": "Discipline"
} 

static func get_fantasy_equivalent(reality_key: String) -> String:
    return OBJECT_MAP.get(reality_key, "Unknown Anomaly")
\end{lstlisting}

\newpage

% ==========================================
% CHAPTER 4: DECKBUILDER STOCHASTICS & COMBAT
% ==========================================
\chapter{Deckbuilder Stochastics \& Combat State Machine}

The combat system is a Turn-Based discrete mathematical simulation. The player manipulates Sets of data (Cards). Visuals are strictly subservient to this data.

\section{Set Theory of Card Piles}
Let $M$ be the Master Deck. At the start of combat, we define three disjoint sets:
Draw Pile $\mathcal{D}$, Hand $\mathcal{H}$, and Discard Pile $\mathcal{X}$.
$$ \mathcal{D} \cup \mathcal{H} \cup \mathcal{X} = M $$
$$ \mathcal{D} \cap \mathcal{H} = \emptyset, \quad \mathcal{H} \cap \mathcal{X} = \emptyset, \quad \mathcal{D} \cap \mathcal{X} = \emptyset $$

\subsection{The Shuffle Axiom}
To satisfy unbiased probability, we must implement the Fisher-Yates shuffle algorithm rather than relying on black-box `.shuffle()` methods without understanding their entropy sources.

\begin{lstlisting}[language=python, caption=Fisher-Yates Shuffle Integration]
func fisher_yates(array: Array) -> Array:
    var result = array.duplicate()
    var n = result.size()
    for i in range(n - 1, 0, -1):
        var j = randi() % (i + 1)
        var temp = result[i]
        result[i] = result[j]
        result[j] = temp
    return result

func draw_card() -> void:
    if draw_pile.is_empty():
        # Mathematical absolute: If D is empty, D = shuffled X, X = empty
        draw_pile = fisher_yates(discard_pile)
        discard_pile.clear()
        
        if draw_pile.is_empty():
            return # Absolute deck exhaustion
            
    var card = draw_pile.pop_back()
    hand.append(card)
    EventBus.emit("card_drawn_to_ui", card)
\end{lstlisting}

\section{Finite State Machine (FSM) of Combat Flow}
Combat is strictly divided into temporal phases. To prevent race conditions (e.g., clicking a card while the enemy is attacking), the entire arena is governed by an FSM.

\begin{center}
\begin{tikzpicture}[->, >=Stealth, auto, node distance=4cm, semithick]
  \tikzstyle{state}=[fill=axiomBg, draw=axiomBorder, text=black, shape=rectangle, rounded corners, minimum height=1cm, align=center]

  \node[state] (Init) {Init\\(Shuffle $M \to \mathcal{D}$)};
  \node[state] (PStart) [below of=Init] {Player Start\\($E=2$, Draw)};
  \node[state] (PAction) [right of=PStart] {Player Action\\(Await Input)};
  \node[state] (PEnd) [above of=PAction] {Player End\\(Discard $\mathcal{H} \to \mathcal{X}$)};
  \node[state] (ETurn) [right of=PEnd] {Enemy Turn\\(Execute AI)};

  \path
  (Init) edge node {} (PStart)
  (PStart) edge node {} (PAction)
  (PAction) edge node {End Turn} (PEnd)
  (PEnd) edge node {} (ETurn)
  (ETurn) edge [bend left] node {} (PStart);
\end{tikzpicture}
\end{center}

\begin{lstlisting}[language=python, caption=Combat FSM Implementation]
extends Node
class_name CombatManager

enum State { INIT, PLAYER_START, PLAYER_ACTION, PLAYER_END, ENEMY_TURN }
var current_state: State = State.INIT

var player_energy: int = 2 

func transition_to(new_state: State) -> void:
    current_state = new_state
    
    match current_state:
        State.PLAYER_START:
            player_energy = 2
            DeckManager.draw_cards(5)
            # Reset Reroll/Retain flags for the round 
            DeckManager.can_reroll = true 
            transition_to(State.PLAYER_ACTION)
            
        State.PLAYER_ACTION:
            EventBus.emit("unlock_player_ui")
            
        State.PLAYER_END:
            EventBus.emit("lock_player_ui")
            DeckManager.discard_hand()
            transition_to(State.ENEMY_TURN)
            
        State.ENEMY_TURN:
            EnemyManager.execute_ai_routine()
\end{lstlisting}

\section{Polymorphic Card Data Structures}
A card is not a visual element; it is a data block. We utilize Godot's \texttt{Resource} paradigm.

\begin{lstlisting}[language=python, caption=Abstract Card Resource Base]
extends Resource
class_name CardData

enum Target { SINGLE, ALL, SELF, RANDOM }

@export var card_name: String
@export var energy_cost: int
@export var base_value: int
@export var target_mode: Target

# Virtual method. Must be overridden.
func play_effect(user: Node, targets: Array[Node]) -> void:
    pass
\end{lstlisting}

To implement the "Thunder" card (Deals X damage to X random enemies), we derive from \texttt{CardData}:

\begin{lstlisting}[language=python, caption=Concrete Implementation of Thunder Card]
extends CardData
class_name CardThunder

@export var number_of_strikes: int

func play_effect(user: Node, targets: Array[Node]) -> void:
    # 'targets' array provided by CombatManager contains all alive enemies
    var valid_targets = targets.filter(func(e): return e.current_hp > 0)
    
    if valid_targets.is_empty(): return
    
    for i in range(number_of_strikes):
        var rand_idx = randi() % valid_targets.size()
        valid_targets[rand_idx].take_damage(base_value)
        # Re-filter in case the strike killed an entity
        valid_targets = valid_targets.filter(func(e): return e.current_hp > 0)
        if valid_targets.is_empty(): break
\end{lstlisting}

\section{Retain and Reroll Mechanics}
The GDD specifies tools to mitigate RNG dependency: Retain and Reroll, available once per round.

\begin{lstlisting}[language=python, caption=Reroll Logic Vector]
func execute_reroll() -> void:
    if not can_reroll: return
    can_reroll = false
    
    # 1. Move current hand to discard pile
    for card in hand:
        discard_pile.append(card)
    hand.clear()
    
    # 2. Draw new hand
    draw_cards(5)
\end{lstlisting}

\newpage

% ==========================================
% CHAPTER 5: NARRATIVE INTEGRATION (THE FRAGMENT SYSTEM)
% ==========================================
\chapter{Narrative Integration: The Fragment System}

The connective tissue between the combat loop and the narrative exploration is the Fragment System. When an enemy is defeated in $\mathcal{C}$, they drop a Fragment. The player shifts to $\mathcal{R}$, utilizes the Fragment on a real-world problem (e.g., the Quiz or Mr. Problem), and gains a mathematical Buff.

\section{The Buff Matrix}
A Buff modifies the base variables of the Combat FSM.

\begin{lstlisting}[language=python, caption=Applying Reality Buffs to Global Memory]
extends Node
class_name RealityInteractionManager

func apply_fragment_to_problem(problem_id: String) -> void:
    if GlobalState.acquired_fragments <= 0:
        return
        
    GlobalState.acquired_fragments -= 1
    
    match problem_id:
        "classroom_quiz_paper":
            # Finding the buff card in the locker
            _grant_combat_buff("courage_boost")
            
func _grant_combat_buff(buff_type: String) -> void:
    match buff_type:
        "courage_boost":
            # Increases base Strike damage universally
            GlobalState.set_flag("buff_courage_active", true)
            # In the CombatManager, all CardData reads this flag 
            # to multiply base_value.
\end{lstlisting}

\section{Dialogue as a Directed Acyclic Graph}
When Hilbert speaks to n.n. (his flying schematic buddy), the conversation is not hard-coded in UI elements. It is processed as a JSON-based Directed Acyclic Graph (DAG) to allow for branching choices.

\begin{lstlisting}[language=python, caption=DAG Dialogue Parser]
extends Node
class_name DialogueSystem

var current_dialogue_tree: Dictionary

func load_dialogue(file_path: String) -> void:
    var file = FileAccess.open(file_path, FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    current_dialogue_tree = json.data
    
    _play_node("start")

func _play_node(node_id: String) -> void:
    var node_data = current_dialogue_tree[node_id]
    var text_to_display = node_data["text"]
    
    # Render text to UI
    EventBus.emit("update_dialogue_ui", text_to_display)
    
    # Handle Options
    if node_data.has("options"):
        EventBus.emit("show_dialogue_options", node_data["options"])
\end{lstlisting}

\chapter{Conclusion and Engineering Mandates}

By implementing this rigid framework, the engineering team is immunized against the most common pitfalls of game development: spaghetti code, race conditions during animations, and state loss during scene transitions. 

\textbf{Final Directives for the Coding Team:}
\begin{enumerate}[label=\Roman*.]
    \item \textbf{Thou shalt not use '\_process' for state checks.} Utilize Signals (EventBus) for all interactions, UI updates, and dimension shifts.
    \item \textbf{Thou shalt isolate data from views.} Cards are \texttt{Resources}. The UI simply reads the Resource and renders the text/icon. Do not put combat logic inside a \texttt{TextureRect} script.
    \item \textbf{Thou shalt respect the Dimension Boundary.} When leaving the Child World, the \texttt{CombatSerializer} must cache the exact size of $\mathcal{D}$, $\mathcal{H}$, and $\mathcal{X}$, alongside Enemy HP, so that when returning from Reality, the state is reconstructed perfectly.
\end{enumerate}

\end{document}