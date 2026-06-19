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
\usetikzlibrary{automata, positioning, arrows.meta, calc}

% Define Code Styles
\definecolor{axiomBg}{RGB}{240, 244, 248}
\definecolor{gdKeyword}{RGB}{192, 57, 43}
\definecolor{gdString}{RGB}{39, 174, 96}
\definecolor{gdComment}{RGB}{127, 140, 141}

\lstdefinestyle{gdscript}{
    backgroundcolor=\color{axiomBg},   
    commentstyle=\color{gdComment}\itshape,
    keywordstyle=\color{gdKeyword}\bfseries,
    stringstyle=\color{gdString},
    basicstyle=\ttfamily\footnotesize,
    breaklines=true,                 
    numbers=left,                    
    numbersep=8pt,                  
    tabsize=4,
    frame=leftline
}
\lstset{style=gdscript}

\title{\textbf{\Huge PROYEKSI PRISMA (DIOSPA)} \\
\vspace{0.5cm}
\Large \textbf{Volume II: Narrative State Machine \& Level Architecture} \\
\vspace{0.2cm}
\normalsize Implementation Blueprint for Godot 4.x}
\author{Directorate of Logic \& Systems Engineering}
\date{\today}

\begin{document}

\maketitle
\tableofcontents
\newpage

% ==========================================
\chapter{The Macro State Machine (Game Flow)}
% ==========================================

The entirety of the game's structure, from start to completion, must be governed by a master Finite State Machine (FSM). We define the set of all global game states $S = \{S_{apt}, S_{hall}, S_{dream1}, S_{class}, S_{dream2}\}$.

The transitions between these states are strictly deterministic, triggered by interactions and combat resolution[cite: 14, 15, 16, 17].

\begin{center}
\begin{tikzpicture}[->, >=Stealth, auto, node distance=3.5cm, semithick]
  \tikzstyle{state}=[fill=white, draw=black, text=black, shape=rectangle, rounded corners, minimum height=1cm, align=center]

  \node[state] (Apt) {$S_{apt}$ (Apartment)};
  \node[state] (Hall) [right of=Apt, xshift=1.5cm] {$S_{hall}$ (Hallway)};
  \node[state] (Dream1) [below of=Hall] {$S_{dream1}$ (Grassy Field)};
  \node[state] (Class) [left of=Dream1, xshift=-1.5cm] {$S_{class}$ (Classroom)};
  \node[state] (Dream2) [below of=Class] {$S_{dream2}$ (Burning Village)};

  \path
  (Apt) edge node {Exit Door} (Hall)
  (Hall) edge node {Panic Attack} (Dream1)
  (Dream1) edge node {Castle Defeated} (Class)
  (Class) edge node {Start Quiz} (Dream2)
  (Dream2) edge [bend right] node {Dimension Shift (Buff)} (Class)
  (Class) edge [bend right] node {Return} (Dream2);
\end{tikzpicture}
\end{center}

To manage these transitions without memory leaks, we implement a \texttt{SceneManager} Autoload.

\begin{lstlisting}[language=python, caption=Deterministic Scene Transition Engine]
extends Node
# Autoload: SceneManager

func transition_to_state(target_state: String) -> void:
    match target_state:
        "S_apt":
            _load_scene("res://scenes/exploration/apartment.tscn")
        "S_hall":
            _load_scene("res://scenes/exploration/hallway.tscn")
        "S_dream1":
            _load_scene("res://scenes/combat/grassy_field.tscn")
        "S_class":
            _load_scene("res://scenes/exploration/classroom.tscn")
        "S_dream2":
            _load_scene("res://scenes/combat/burning_village.tscn")

func _load_scene(path: String) -> void:
    # Optional: Insert fade-to-black animation logic here [cite: 242, 342]
    get_tree().change_scene_to_file(path)
\end{lstlisting}

\newpage

% ==========================================
\chapter{Phase I: The Baseline Reality}
% ==========================================

\section{Level 0: The Apartment ($S_{apt}$)}
The apartment is explicitly defined as a $12 m^2$ enclosed space[cite: 209]. This geometric constraint forces the player to pace within a tight boundary, simulating Hilbert's psychological entrapment[cite: 208, 209]. The visual tone is strictly "Cold"[cite: 341].

\subsection{Interactable Vector Matrix}
We populate the 2D space with coordinates corresponding to the required interactables[cite: 327, 332].

\begin{itemize}
    \item \textbf{Bed:} Interaction outputs "Sleep Again? (Y/N)"[cite: 337]. If 'Y', triggers the 'Reminder Kuliah' cutscene[cite: 337]. If 'N', outputs "Probably later."[cite: 337].
    \item \textbf{Desk:} Outputs "Papers... Unfinished... Not Much"[cite: 334]. Secondary trigger: Open Drawer, revealing "A Picture... Not Important"[cite: 334, 335].
    \item \textbf{Guitar:} Outputs "Not really in the mood to play."[cite: 336].
    \item \textbf{Bathroom Array:} Includes Toilet ("Just a toilet. Nothing Much.") and Shower ("A shower...")[cite: 338, 339, 340].
\end{itemize}

\subsection{The Shower Sequence (Color Interpolation)}
When Hilbert enters the shower, the narrative dictates a shift in psychological weight[cite: 227]. The atmosphere transitions from bright morning light to a dark, desolate environment[cite: 330, 331]. We model this programmatically via linear interpolation (`lerp`) of the \texttt{CanvasModulate} node.

\begin{lstlisting}[language=python, caption=Atmospheric Shift via CanvasModulate]
extends Node2D
class_name ApartmentLevel

@onready var atmosphere_modulator: CanvasModulate = $CanvasModulate

const COLOR_MORNING = Color(1.0, 0.95, 0.9) # Cerah bersinar [cite: 330]
const COLOR_DEPRESSION = Color(0.3, 0.3, 0.4) # Gelap, sepi [cite: 330, 341]

func _on_shower_interacted() -> void:
    # The water turns freezing cold, contemplating [cite: 227]
    var tween = create_tween()
    tween.tween_property(atmosphere_modulator, "color", COLOR_DEPRESSION, 3.0)
    
    # Trigger internal monologue
    DialogueSystem.play_line("wouldn't it be nice to feel the silence forever...") # [cite: 223]
\end{lstlisting}

\section{Level 1: The Hallway ($S_{hall}$)}
Hilbert exits the apartment into the faculty building[cite: 232, 234]. The hallway is cold and tense[cite: 345, 348]. 

\subsection{The Panic Attack \& Dimension Shift Vector}
As Hilbert walks, a specific trigger area (\texttt{Area2D}) activates the panic sequence. The murmurs fade, and the Dimension Shift is forcibly invoked[cite: 240, 241, 349]. 

\begin{lstlisting}[language=python, caption=Passive Narrative Dimension Shift]
extends Area2D

func _on_body_entered(body: Node2D) -> void:
    if body is ExplorationPlayer and not GlobalState.has_flag("shift_1_done"):
        # Darkening the world [cite: 241, 349]
        EventBus.emit("play_sound", "murmur_fade_out") # [cite: 240, 241]
        
        # "Living in fiction is fun, isn't it?" [cite: 238]
        DialogueSystem.play_memory_sequence("friend_memory_1") 
        
        await get_tree().create_timer(2.0).timeout
        GlobalState.set_flag("shift_1_done", true)
        SceneManager.transition_to_state("S_dream1") # [cite: 242, 350]
\end{lstlisting}

\newpage

% ==========================================
\chapter{Phase II: The Inner Childhood Dream}
% ==========================================

\section{Level 2: Grassy Field \& Tutorial ($S_{dream1}$)}
The environment immediately shifts from a cold reality to a warm, vibrant grassy field[cite: 244, 246, 351, 358]. The system must now instantiate the Deckbuilder combat logic.

\subsection{The Introduction of $n.n.$}
The flying mechanical companion, $n.n.$, acts as the tutorial node[cite: 253, 255, 256]. 

\begin{lstlisting}[language=python, caption=Spawning the Companion]
func _ready() -> void:
    # "HEY YOU THERE!" [cite: 249, 250]
    var nn_instance = preload("res://actors/nn_companion.tscn").instantiate()
    add_child(nn_instance)
    
    # Initialize Tutorial Deck
    DeckManager.master_deck = [
        preload("res://data/cards/strike.tres"), # [cite: 118]
        preload("res://data/cards/defend.tres")  # [cite: 127]
    ]
\end{lstlisting}

\subsection{Combat Instance I: The Castle Boss}
The narrative dictates that the castle itself awakens to attack Hilbert[cite: 265, 267]. This is the fantasy representation of the classroom door[cite: 353]. 

We instantiate the Combat FSM derived in Volume I. When the Castle's HP reaches $0$, we intercept the death signal to trigger the return to reality[cite: 277, 283, 285].

\begin{lstlisting}[language=python, caption=Combat Resolution and Return]
func _on_castle_boss_defeated() -> void:
    # "Wow, that was awesome Hilbert." [cite: 279]
    DialogueSystem.play_dialogue("nn_congrats")
    
    # "This is only a dream, you need to go back to reality." [cite: 283]
    await DialogueSystem.finished
    
    # The world shatters like glass [cite: 285, 359]
    VisualEffects.play_glass_shatter()
    SceneManager.transition_to_state("S_class") # [cite: 286]
\end{lstlisting}

\newpage

% ==========================================
\chapter{Phase III: The Degradation of Reality}
% ==========================================

\section{Level 3: The Classroom ($S_{class}$)}
Hilbert awakens back in reality, inside the classroom[cite: 286, 288, 360]. The environment is dark and tense[cite: 362, 369]. 

\subsection{The Classroom Interactables}
The room contains specific interactive vectors to establish the stakes[cite: 363].
\begin{itemize}
    \item \textbf{Orang 1:} Outputs "Uhh... You okay?"[cite: 365].
    \item \textbf{Orang 2:} Outputs "Stop looking at me! Weirdo."[cite: 366].
    \item \textbf{Locker:} Acquiring a Buff Card[cite: 368].
    \item \textbf{Desk:} Outputs "Start the quiz?" If Yes, shifts to next scene. If No, outputs "Better prepare myself."[cite: 367].
\end{itemize}

When the player selects 'Yes' at the desk, the Professor begins a monologue[cite: 290, 291]. The quiz represents an insurmountable problem, triggering the second Dimension Shift[cite: 295, 297, 300].

\section{Level 4: The Burning Village ($S_{dream2}$)}
The final prototype level forces Hilbert into a high-stakes combat scenario. The grassy field is replaced by a burning village[cite: 301, 302, 372]. The color palette is strictly "Hot to warm"[cite: 376].

\subsection{Active Dimension Shifting \& Fragment Utilization}
During the boss fight with the "leader of the pack", Hilbert's standard attacks deal negligible damage[cite: 308, 313]. $n.n.$ explicitly instructs the player to warp back to reality[cite: 314, 316].

This requires the system to utilize the \texttt{ShiftManager} (Charge Calculus $C \ge 3$)[cite: 57, 58].

\begin{lstlisting}[language=python, caption=Fragment Logic Implementation]
# Inside Reality Hub (Classroom Paused State)
func _on_use_fragment_pressed() -> void:
    # Use fragment on the paper monster [cite: 319]
    if GlobalState.acquired_fragments > 0:
        GlobalState.acquired_fragments -= 1
        
        # Apply deterministic buff: Confidence over Insecurity [cite: 66, 68]
        GlobalState.set_flag("buff_confidence_active", true)
        
        # Player feels lighter and stronger [cite: 320]
        # Return to Child World combat exactly where it left off [cite: 321]
        SceneManager.transition_to_state("S_dream2_resume")
\end{lstlisting}

By returning to the combat with the \texttt{buff\_confidence\_active} flag evaluating to \texttt{true}, the base damage array is multiplied by a defined scalar, allowing the player to defeat the boss[cite: 323, 324]. The prototype sequence then concludes, returning the world to a state of calmness[cite: 325].

\end{document}