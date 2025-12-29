# Test Strategy - Dog vs Owner Game
## Comprehensive Testing Framework

**Projekt:** Dog vs Owner Game (Godot 4.5)  
**Version:** 1.0  
**Datum:** 10. Dezember 2025  
**Status:** In Entwicklung  
**Autoren:** Entwicklungsteam

---

## 1. Analyse der Game Features

### 1.1 Kern-Game-Features

#### 1.1.1 Spielmechaniken
- **Dog AI**: Utility-basiertes KI-System für Hundenavigation und Entscheidungsfindung
- **Player-Steuerung**: 3rd-Person Charakter mit Kamera-Kontrolle und Bewegung
- **Spielfeld**: 3D-Umgebung mit Navigations-Mesh und interaktiven Objekten
- **Items/Treats**: Verschiedene Snack-Typen (Hundefutter, Käse, Schokolade, Gift)
- **Bewegungs-System**: Navigation Agent mit Pathfinding
- **Animationen**: Character-Animationen (Laufen, Idle, Fressen, Angriff)
- **Game-State**: Globaler GameState für Spielzustand-Verwaltung

#### 1.1.2 AI-Verhalten (Utility AI)
- **EAT_SNACK**: Hund navigiert zu Snacks und frisst diese
- **FLEE_FROM_OWNER**: Hund flieht vor dem Spieler
- **POOP**: Strategische Platzierung von Hindernissen
- **IDLE**: Kurze Orientierungspausen
- **DEATH**: Spielende-Bedingungen

#### 1.1.3 Technische Komponenten
- **NavigationAgent3D**: 3D-Pathfinding-System
- **AnimationPlayer**: Character-Animation Management
- **CharacterBody3D**: Physics-basierte Bewegung
- **3D-Kamera**: Third-Person Perspektive mit Maus-Steuerung
- **Gruppe System**: Schnelle Objekt-Verwaltung (dog, player, treats)

---

## 2. Test-Ziele (Functional & Non-Functional)

### 2.1 Funktionale Test-Ziele

#### 2.1.1 Player-Bewegung & Steuerung
- ✅ Bewegungsinput (WASD) wird korrekt verarbeitet
- ✅ Kamera folgt Maus-Bewegung mit korrekter Sensitivität
- ✅ Character dreht sich in Bewegungsrichtung
- ✅ Bewegung ist kamera-relativ (nicht absolut)
- ✅ Gravity wirkt korrekt auf den Player
- ✅ Animationen (Run/Idle) werden korrekt abgespielt

#### 2.1.2 Dog AI Navigation
- ✅ Hund findet nächsten Snack korrekt
- ✅ Hund navigiert zu Snack mit Navigation Agent
- ✅ Hund stoppt bei Ziel-Ankunkt
- ✅ Hund wiedererkennt unerreichbare Ziele
- ✅ Hund aktualisiert Ziel periodisch (0.5 Sekunden)
- ✅ Navigations-Pfad wird korrekt berechnet

#### 2.1.3 Dog AI Verhalten (Utility)
- ✅ EAT_SNACK Utility wird mit allen Faktoren berechnet
- ✅ FLEE_FROM_OWNER Utility berücksichtigt Distanz
- ✅ POOP Utility respektiert Cooldown
- ✅ IDLE Utility als Fallback-Aktion
- ✅ Aktion mit höchstem Score wird gewählt
- ✅ Verhalten ändert sich dynamisch mit Kontext

#### 2.1.4 Fressen-Mechanik
- ✅ Eat-Animation wird korrekt abgespielt
- ✅ Hund bewegt sich nicht während Fressen
- ✅ Eat-Dauer wird korrekt gemessen
- ✅ Ziel wird nach Fressen verworfen
- ✅ Gravity funktioniert auch während Fressen
- ✅ Nach Fressen wird neuer Snack gesucht

#### 2.1.5 Game-State Management
- ✅ GameState wird als Autoload geladen
- ✅ Spielzustand bleibt über Scene-Wechsel erhalten
- ✅ Globale Variablen sind konsistent

#### 2.1.6 UI & Feedback
- ✅ HUD zeigt relevante Informationen
- ✅ Menü funktioniert korrekt
- ✅ Scene-Übergänge funktionieren

### 2.2 Non-Funktionale Test-Ziele

#### 2.2.1 Performance
- ⚡ Dog AI Update (< 16ms pro Frame @ 60 FPS)
- ⚡ Navigation Pathfinding (< 10ms pro Berechnung)
- ⚡ Animationen (flüssig ohne Stuttering)
- ⚡ 3D-Rendering (60+ FPS durchgehend)
- ⚡ Memory-Nutzung (< 500MB für typisches Gameplay)

#### 2.2.2 Stabilität & Zuverlässigkeit
- 🛡️ Keine NaN-Werte in Position/Rotation
- 🛡️ Keine Infinite-Loops in AI
- 🛡️ Keine Null-Reference Exceptions
- 🛡️ Game läuft stabil über 30 Min+ Spielzeit
- 🛡️ AI erholt sich von Edge-Cases

#### 2.2.3 Responsive Behavior
- 🎮 AI reagiert innerhalb von 0.5s auf Umgebungsänderungen
- 🎮 Player-Input hat sofortige visuelle Reaktion
- 🎮 Keine Verzögerung bei Zielwechsel

### 2.3 AI-Spezifische Test-Ziele

#### 2.3.1 Behavior Variety
- 🐕 Hund zeigt unterschiedliche Verhaltensweisen basierend auf Situation
- 🐕 Utility-Scores variieren mit Kontext
- 🐕 Keine vorhersehbare monotone Bewegung

#### 2.3.2 Schwierigkeit & Balance
- ⚖️ Hund ist für Spieler erreichbar aber nicht trivial
- ⚖️ Snack-Auswahl ist realistisch
- ⚖️ Flucht-Verhalten ist glaubwürdig

#### 2.3.3 Konsistenz
- 📋 Gleiche Situation führt zu konsistenten Ergebnissen
- 📋 Keine zufälligen Fehler im Verhalten
- 📋 Regelwerk wird konsistent angewendet

---

## 3. Test Classification Model

### 3.1 Unit Tests

**Ziel:** Isolierte Tests einzelner Komponenten

#### 3.1.1 Utility Calculation Tests
```
Kategorie: AI Logic
Komponente: Utility Score Calculator

Test Cases:
- test_eat_snack_utility_base_score()
  → Verify: Base Score (0.7) wird korrekt angewendet
  → Input: Einfache Snack-Situation
  → Expected: Score >= 0.7

- test_eat_snack_utility_hunger_factor()
  → Verify: Hunger-Faktor (0.0 - 0.3) wird richtig skaliert
  → Input: Hunger Level 0.5
  → Expected: Score erhöht sich um 0.15

- test_eat_snack_utility_distance_factor()
  → Verify: Distanz-Faktor reduziert Score
  → Input: Max Sichtweite = 50, Snack-Distanz = 25
  → Expected: Score reduziert um (25/50) * 0.2 = 0.1

- test_eat_snack_utility_owner_danger_factor()
  → Verify: Besitzer-Nähe reduziert Utility korrekt
  → Input: Besitzer < 3 Einheiten entfernt
  → Expected: Score reduziert um 0.3

- test_flee_utility_threat_distance()
  → Verify: Bedrohungs-Faktor basierend auf Distanz
  → Input: Besitzer < 2 Einheiten entfernt
  → Expected: Utility > 0.7

- test_poop_utility_cooldown()
  → Verify: Cooldown wird respektiert
  → Input: Cooldown aktiv
  → Expected: Utility = 0.0

- test_utility_clamping()
  → Verify: Alle Utility-Werte sind im Range [0.0, 1.0]
  → Input: Extreme Parameter
  → Expected: Clamp funktioniert auf [0.0, 1.0]
```

#### 3.1.2 Navigation Tests
```
Kategorie: Movement
Komponente: NavigationAgent3D

Test Cases:
- test_target_reachability()
  → Verify: Agent erkennt erreichbare vs. unerreichbare Ziele
  → Input: Verschiedene Positionen (erreichbar/unerreichbar)
  → Expected: is_target_reachable() return bool korrekt

- test_path_calculation()
  → Verify: Pathfinding berechnet gültige Pfade
  → Input: Start- und Zielposition
  → Expected: Path ist nicht leer, keine Sprünge

- test_next_position_update()
  → Verify: get_next_path_position() wird aktualisiert
  → Input: Agent folgt Pfad
  → Expected: Position ändert sich pro Frame
```

#### 3.1.3 Animation Tests
```
Kategorie: Visual Feedback
Komponente: AnimationPlayer

Test Cases:
- test_animation_exists()
  → Verify: Erforderliche Animationen sind geladen
  → Input: AnimationPlayer mit Animations
  → Expected: "Gallop", "Eating", "Run", "Idle" existieren

- test_animation_playback()
  → Verify: Animation wird korrekt abgespielt
  → Input: anim.play("AnimName")
  → Expected: Aktuelle Animation = "AnimName"

- test_loop_mode()
  → Verify: Loop-Modi werden korrekt gesetzt
  → Input: Gallop (linear) vs. Eating (keine Schleife)
  → Expected: Animation looped korrekt oder stoppt
```

#### 3.1.4 Physics Tests
```
Kategorie: Movement
Komponente: CharacterBody3D

Test Cases:
- test_gravity_application()
  → Verify: Gravity wird auf Y-Achse angewendet
  → Input: Character in der Luft
  → Expected: velocity.y wird negativ

- test_is_on_floor()
  → Verify: Floor Detection funktioniert
  → Input: Character auf Boden
  → Expected: is_on_floor() return true

- test_move_and_slide()
  → Verify: Bewegung wird angewendet
  → Input: velocity = (5, 0, 5)
  → Expected: Position ändert sich
```

### 3.2 Integration Tests

**Ziel:** Tests für Zusammenspiel mehrerer Komponenten

#### 3.2.1 Dog AI System Integration
```
Kategorie: AI System
Komponente: Dog (Skript) + Navigation + Utility

Test Cases:
- test_find_nearest_treat()
  → Verify: Snack-Suche funktioniert mit mehreren Snacks
  → Setup: 5 Snacks in verschiedenen Positionen
  → Expected: Nächster Snack wird gefunden
  → Assertion: target_treat.position == nächster_snack.position

- test_dog_navigation_to_treat()
  → Verify: Hund navigiert zu gefundenem Snack
  → Setup: Hund und Snack in gleicher Szene, NavMesh aktiv
  → Expected: Hund bewegt sich Richtung Snack
  → Assertion: distance_to_target verringert sich

- test_target_update_interval()
  → Verify: Ziel wird alle 0.5 Sekunden aktualisiert
  → Setup: target_update_timer, mehrere Snacks
  → Expected: find_nearest_treat() wird periodisch aufgerufen
  → Assertion: target_treat kann sich alle 0.5s ändern

- test_eating_mechanics()
  → Verify: Eat-Animation und Timer funktionieren zusammen
  → Setup: Dog bei Snack
  → Expected: is_eating = true, Timer läuft ab
  → Assertion: Nach eat_duration: is_eating = false

- test_dog_movement_during_eating()
  → Verify: Hund bewegt sich nicht während Fressen
  → Setup: Dog.is_eating = true
  → Expected: velocity.x = 0, velocity.z = 0
  → Assertion: global_position.x/z ändern sich nicht
```

#### 3.2.2 Player-Dog Interaction
```
Kategorie: Gameplay
Komponente: Player + Dog + Utilities

Test Cases:
- test_player_can_catch_dog()
  → Verify: Player kann zu Hund-Position navigieren
  → Setup: Player und Dog in gleicher Szene
  → Expected: Player kann Hund erreichen
  → Assertion: distance(player, dog) < tolerance

- test_dog_flees_from_player()
  → Verify: Dog nutzt FLEE Utility wenn Player nah ist
  → Setup: Player < 3 Einheiten vom Dog
  → Expected: Dog weicht aus
  → Assertion: distance(player, dog) bleibt > 2

- test_player_camera_follows_character()
  → Verify: Kamera folgt Player-Position
  → Setup: Player mit Camera
  → Expected: Camera-Position an Player gebunden
  → Assertion: camera_pos ≈ player_pos + offset
```

#### 3.2.3 Navigation System Integration
```
Kategorie: Movement
Komponente: NavigationAgent + CharacterBody3D

Test Cases:
- test_vertical_navigation()
  → Verify: Hund kann auf verschiedene Höhen navigieren
  → Setup: NavMesh mit Ebenen unterschiedlicher Höhe
  → Expected: Hund navigiert vertikal
  → Assertion: y-position kann sich ändern > 0.5

- test_path_following()
  → Verify: Hund folgt berechnetem Pfad
  → Setup: Multi-Point Pfad zu Ziel
  → Expected: Hund besucht Waypoints in Reihenfolge
  → Assertion: Distanz zu Ziel nimmt ab

- test_smooth_rotation()
  → Verify: Hund dreht sich flüssig zum Ziel
  → Setup: rotation_speed, angle_diff
  → Expected: Rotation erfolgt sanft
  → Assertion: rotation.y ändert sich kontinuierlich
```

#### 3.2.4 Animation System Integration
```
Kategorie: Visual Feedback
Komponente: AnimationPlayer + Movement + Behavior

Test Cases:
- test_idle_to_run_transition()
  → Verify: Animation wechselt von Idle zu Run
  → Setup: Player bewegt sich
  → Expected: IDLE_ANIM → RUN_ANIM
  → Assertion: current_animation == RUN_ANIM

- test_run_to_idle_transition()
  → Verify: Animation wechselt von Run zu Idle
  → Setup: Player stoppt Bewegung
  → Expected: RUN_ANIM → IDLE_ANIM
  → Assertion: current_animation == IDLE_ANIM

- test_pickup_animation_blocks_movement()
  → Verify: _is_playing_pickup = true blockiert Bewegung
  → Setup: play_pickup_animation() aufgerufen
  → Expected: Player-Speed = 0.0
  → Assertion: player nicht beweglich während Animation
```

### 3.3 Gameplay Tests

**Ziel:** Tests für vollständige Spielabläufe und Spielerlebnis

#### 3.3.1 Game Flow Tests
```
Kategorie: Gameplay
Scope: End-to-End Szenarien

Test Case 1: "Snack Catching Scenario"
- Setup: Game starten, mehrere Snacks spawnen
- Aktion: Hund bewegt sich zu Snacks und frisst
- Expected: Hund frisst mindestens 3 Snacks
- Validation:
  * Hund bewegt sich logisch
  * Animationen spielen korrekt ab
  * Snacks verschwinden nach Fressen
  * Neues Ziel wird gefunden

Test Case 2: "Player Chase Scenario"
- Setup: Game starten, Player näher an Hund
- Aktion: Player versucht, Hund zu fangen
- Expected: Hund flieht intelligente Fluchtrouten
- Validation:
  * Dog Fleeing-Utility triggert
  * Hund weicht aus vor Player
  * Fluchtroute ist sinnvoll (nicht zirkulär)
  * Hund kann Snack immer noch finden

Test Case 3: "Strategic Hindrance Scenario"
- Setup: Game mit POOP Action
- Aktion: Hund platziert Haufen strategisch
- Expected: Haufen behindern Player-Bewegung
- Validation:
  * POOP Utility wird kalkuliert
  * Cooldown wird beachtet
  * Haufen erscheinen an sinnvollen Orten
  * Player muss ausweichen

Test Case 4: "Resource Management Scenario"
- Setup: Begrenzte Leben/Snacks
- Aktion: Spieler versucht, Hund zu stoppen
- Expected: Spiel endet bei Game-Over-Bedingung
- Validation:
  * Leben-Counter funktioniert
  * Schokolade-Vergiftung wird gezählt
  * Gift führt zu sofortigem Tod
  * Game-Over wird korrekt getriggert
```

#### 3.3.2 AI Behavior Quality Tests
```
Kategorie: AI Behavior
Scope: Realismus und Intelligenz

Test Case: "Contextual Decision Making"
- Scenario: Mehrere Snacks, Player in verschiedenen Positionen
- Expected: Hund wählt Snack basierend auf:
  * Nähe (Distanz-Faktor)
  * Sicherheit (Owner-Gefahr-Faktor)
  * Attraktivität (Snack-Wert-Faktor)
  * Risiko (Leben-Faktor)
- Validation:
  * Utility-Scores für alle Snacks berechnet
  * Höchster Score wird gewählt
  * Entscheidung ändert sich mit Kontext

Test Case: "Behavior Variety"
- Scenario: 10 Minuten Gameplay
- Expected: Hund zeigt verschiedene Verhaltensweisen
- Validation:
  * Nicht-konstante Bewegungsmuster
  * Abwechslung zwischen Fressen und Flucht
  * Variabilität in Snack-Auswahl
  * Realistische Aktivitätsmuster
```

#### 3.3.3 User Experience Tests
```
Kategorie: Usability
Scope: Player Experience

Test Case: "Input Responsiveness"
- Aktion: WASD-Input, Maus-Bewegung
- Expected: Sofortige visuelle Reaktion (< 33ms)
- Validation:
  * Character dreht sich sofort bei Input
  * Kamera folgt Maus
  * Keine Verzögerung oder Input-Lag

Test Case: "Visual Clarity"
- Scenario: Normales Gameplay
- Expected: Spieler kann Hund und Snacks klar sehen
- Validation:
  * Objekte sind deutlich sichtbar
  * Kamera-Winkel ist sinnvoll
  * Keine Clipping-Probleme
  * Animation sind flüssig

Test Case: "Game Balance"
- Scenario: Mehrere Gameplay-Sessions
- Expected: Spiel ist weder zu leicht noch zu schwer
- Validation:
  * Hund ist erreichbar aber nicht trivial
  * Snack-Auswahl dauert durchschnittlich 5-10 Sekunden
  * Erfolgsrate des Spielers ist ~40-50%
```

---

## 4. Test Coverage & Prioritization Rules

### 4.1 Coverage Criteria

#### 4.1.1 Code Coverage Targets
```
Ziel: Mindestens 70% Statement Coverage für kritische Systeme

Kritische Systeme (Target: 85%+):
- dog.gd (AI Logic): 85% target
- player.gd (Input & Movement): 80% target
- Utility Calculator (wenn separate): 90% target

Wichtige Systeme (Target: 70%+):
- main_with_furniture.gd: 70%
- hud.gd: 70%

Weniger kritisch (Target: 50%+):
- UI/Menu Systeme: 50%
- non-essential Features: 40%
```

#### 4.1.2 Feature Coverage Matrix

| Feature | Unit Tests | Integration Tests | Gameplay Tests | Status |
|---------|-----------|------------------|----------------|--------|
| Dog Navigation | ✅ High | ✅ High | ✅ High | Critical |
| Utility Calculation | ✅ Very High | ✅ High | ✅ Medium | Critical |
| Player Movement | ✅ Medium | ✅ High | ✅ High | Critical |
| Animation System | ✅ Medium | ✅ High | ✅ High | Critical |
| Eating Mechanics | ✅ High | ✅ High | ✅ High | Critical |
| Fleeing Behavior | ✅ Medium | ✅ High | ✅ High | High |
| POOP Mechanic | ✅ Medium | ✅ Medium | ✅ Medium | Medium |
| Game State | ✅ Low | ✅ Medium | ✅ Medium | Medium |
| UI/HUD | ⚠️ Low | ✅ Low | ✅ Low | Low |
| Camera System | ⚠️ Low | ✅ Medium | ✅ High | Medium |

### 4.2 Prioritization Rules

#### 4.2.1 Priority Levels

**Priority 1 - CRITICAL (Must Test)**
```
Rules:
- Direkt Spielende des Spiels
- Core Game Loop
- Häufig ausgeführter Code (jeden Frame)
- Sicherheitskritisch (keine Crashes)

Test Cases:
- Dog AI Basic Navigation
- Player Input Processing
- Physics & Gravity
- Animation Playback
- Game State Persistence
```

**Priority 2 - HIGH (Should Test)**
```
Rules:
- Core Gameplay-Mechaniiken
- AI-Entscheidungslogik
- Komplexe Interaktionen
- Performance-kritisch

Test Cases:
- Utility Calculation Accuracy
- Dog-Player Interaction
- Snack Selection Logic
- Fleeing Behavior
- Eating Animation Timing
```

**Priority 3 - MEDIUM (Nice to Have)**
```
Rules:
- Spezielle Mechaniken
- Edge Cases
- Visuelle Feedback
- Non-critical Features

Test Cases:
- POOP Mechanic Positioning
- Camera Edge Cases
- Animation Transitions
- UI Responsiveness
```

**Priority 4 - LOW (Optional)**
```
Rules:
- Kosmetische Features
- Seltene Szenarien
- Menu Systems
- Accessibility Features

Test Cases:
- Menu Navigation
- Settings Persistence
- Graphical Options
- Sound/Audio
```

#### 4.2.2 Execution Order
```
Sprint / Test Run Sequenzen:

Phase 1 (Day 1-2): Critical Tests Only
- Dog Navigation (unit + integration)
- Player Movement (unit + integration)
- Physics & Gravity (unit)
- Animation Basic (unit)
- Game State (unit)
Estimated Time: 2-3 hours

Phase 2 (Day 3-4): High Priority
- Utility Calculation (unit + integration)
- Dog-Player Interaction (integration + gameplay)
- Eating Mechanics (integration)
- Fleeing Behavior (integration + gameplay)
Estimated Time: 3-4 hours

Phase 3 (Day 5): Medium & Low Priority
- POOP Mechanic (integration + gameplay)
- Camera System (integration + gameplay)
- UI/HUD (integration)
- Edge Cases & Robustness
Estimated Time: 2-3 hours

Phase 4: Regression & Performance
- Alle vorherigen Tests re-run
- Performance Profiling
- Stability Tests (30+ min gameplay)
Estimated Time: 2-3 hours
```

---

## 5. Metrics for AI Behavior Validation

### 5.1 Quantitative Metrics

#### 5.1.1 Decision Quality Metrics
```
Metric 1: Utility Score Accuracy
- Definition: Prozentsatz korrekter Utility-Berechnungen
- Formula: (Correct Calculations / Total Calculations) × 100
- Target: > 98%
- Measurement: Unit Tests für alle Utility-Funktionen
- Example:
  * Expected Utility: 0.65
  * Calculated Utility: 0.65 ± 0.01
  * Pass: ✅

Metric 2: Action Selection Consistency
- Definition: Konsistenz bei gleicher Spielsituation
- Formula: (Identical Decisions / Total Decisions) × 100
- Target: > 95%
- Measurement: Gleiche Situation 100× testen
- Example:
  * Situation: Hund, 2 Snacks in gleicher Position
  * Run 1: EAT_SNACK (Utility: 0.78)
  * Run 2: EAT_SNACK (Utility: 0.78)
  * Result: 100% consistent ✅

Metric 3: Decision Diversity
- Definition: Verhaltensvielfalt in verschiedenen Szenarien
- Formula: (Different Behaviors / Possible Behaviors) × 100
- Target: > 60%
- Measurement: 100 Gameplay Sessions analysieren
- Expected Behaviors:
  * EAT_SNACK: ~60% of frames
  * FLEE_FROM_OWNER: ~20% of frames
  * IDLE: ~15% of frames
  * POOP: ~5% of frames
```

#### 5.1.2 Performance Metrics
```
Metric 1: AI Frame Time
- Definition: Zeit für Dog AI Update pro Frame
- Target: < 5ms @ 60 FPS
- Measurement: Profiler (GDScript Timer)
- Acceptable Range: 1-5ms
- Formula: (Total Time / Frame Count)

Metric 2: Navigation Update Frequency
- Definition: Wie oft wird Pfad neu berechnet
- Target: 2× pro Sekunde (0.5s Interval)
- Measurement: target_update_timer logging
- Expected: 120 Updates in 60 Sekunden ± 5%

Metric 3: Memory Usage
- Definition: Memory für Dog AI System
- Target: < 5MB (Dog + Navigation + AI)
- Measurement: Profiler Memory Snapshot
- Baseline: Empty Scene vs. mit Dog

Metric 4: Animation Smoothness
- Definition: FPS während intensiven Animationen
- Target: > 55 FPS durchgehend
- Measurement: FPS Counter während Gameplay
- Threshold: Nicht unter 50 FPS fallen
```

#### 5.1.3 Behavior Pattern Metrics
```
Metric 1: Snack Selection Patterns
- Definition: Wie oft wählt der Hund verschiedene Snacks?
- Measurement: Snack-Logs über 100 Selections
- Expected Distribution:
  * Hundefutter: 40-50%
  * Käse: 30-40%
  * Schokolade: 10-15%
  * Gift: 2-5%
- Analysis: Ist Verteilung mit Utility-Formeln konsistent?

Metric 2: Fleeing Success Rate
- Definition: Wie oft kann Hund erfolgreich fliehen?
- Formula: (Successful Flees / Flee Attempts) × 100
- Target: > 70%
- Definition Success: Distanz zu Owner erhöht sich

Metric 3: Average Decision Time
- Definition: Durchschnittliche Zeit von Problem zu Entscheidung
- Target: 0.5s (= TARGET_UPDATE_INTERVAL)
- Measurement: Target-Change Logging
```

### 5.2 Qualitative Metrics

#### 5.2.1 Behavior Realism
```
Metric: "Does the dog act like a real dog?"

Evaluation Checklist:
□ Hund wählt interessante Snacks (nicht zufällig)
□ Hund flieht intelligent vor Gefahr (nicht panisch)
□ Hund zeigt interessierten Schnüffeln (Animation)
□ Hund ändert Meinung wenn Situation sich ändert
□ Hund nutzt Hindernisse strategisch

Scoring:
- 5 Points: Sehr realistisches Verhalten
- 4 Points: Gutes realistisches Verhalten
- 3 Points: Akzeptables Verhalten
- 2 Points: Etwas unrealistisch aber spielbar
- 1 Point: Sehr unrealistisch
- Target Score: > 4.0 / 5.0
```

#### 5.2.2 Gameplay Challenge
```
Metric: "Is the game challenging and fun?"

Evaluation Checklist:
□ Hund ist erreichbar (nicht unmöglich zu fangen)
□ Hund ist eine echte Herausforderung (nicht trivial)
□ Kein vorhersehbares Muster im Verhalten
□ Spieler fühlt sich von Hund überlistet
□ Mehrfache Spielsessions sind unterschiedlich

Scoring:
- 5 Points: Perfekte Balance
- 4 Points: Sehr gutes Gameplay
- 3 Points: Ausreichend herausfordernd
- 2 Points: Zu leicht oder zu schwer
- 1 Point: Unspielbar
- Target Score: > 4.0 / 5.0
```

#### 5.2.3 Technical Quality
```
Metric: "Are there bugs or glitches?"

Evaluation:
□ Keine T-Pose oder Animation Glitches
□ Keine Clipping durch Wände
□ Keine Infinite Loops oder Freezes
□ Keine Konsolen-Fehler
□ Keine NaN / Infinity Werte
□ Stabile 60 FPS ohne Drops

Target:
- Zero Critical Bugs
- < 3 Minor Issues per 30min Session
```

### 5.3 Metric Dashboard Example

```
┌─────────────────────────────────────────────────────────┐
│         AI Behavior Validation Dashboard                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Decision Quality:                                       │
│   Utility Accuracy ........... 98.5% ✅ (Target: 98%)  │
│   Selection Consistency ...... 96.2% ✅ (Target: 95%)  │
│   Behavior Diversity ......... 65.3% ✅ (Target: 60%)  │
│                                                          │
│ Performance:                                            │
│   AI Frame Time ............. 3.2ms ✅ (Target: 5ms)   │
│   Navigation Updates/s ....... 2.1 ✅ (Target: 2.0)    │
│   FPS Average ............... 58.7 ✅ (Target: 55+)    │
│                                                          │
│ Behavior Patterns:                                      │
│   Snack Selection - Hundefutter ... 45% ✅             │
│   Snack Selection - Käse .......... 35% ✅             │
│   Fleeing Success Rate ............ 72% ✅             │
│                                                          │
│ Qualitative Scores:                                     │
│   Realism ..................... 4.2/5.0 ✅             │
│   Gameplay Challenge .......... 4.1/5.0 ✅             │
│   Technical Quality ........... 4.8/5.0 ✅             │
│                                                          │
│ Overall Health: ★★★★★ GOOD                             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 6. Test Strategy Document Structure

### 6.1 Dokumentation übersicht
```
Test Strategy Dokumentation:
├── TEST_STRATEGY.md (dieses Dokument)
│   ├── 1. Feature Analysis
│   ├── 2. Test Objectives
│   ├── 3. Test Classification
│   ├── 4. Coverage & Prioritization
│   └── 5. Metrics
│
├── TEST_PLAN.md (detaillierte Test-Cases)
│   ├── Unit Test Specifications
│   ├── Integration Test Specifications
│   ├── Gameplay Test Specifications
│   └── Test Data & Fixtures
│
├── AI_BEHAVIOR_TESTS.gd (GDScript Test Suite)
│   ├── Utility Calculation Tests
│   ├── Navigation Tests
│   ├── AI Decision Tests
│   └── Integration Tests
│
├── PLAYER_MOVEMENT_TESTS.gd (GDScript Test Suite)
│   ├── Input Tests
│   ├── Movement Tests
│   ├── Camera Tests
│   └── Animation Tests
│
├── TEST_RESULTS.md (Test Execution Report)
│   ├── Datum & Ausführer
│   ├── Test Summary
│   ├── Passed / Failed Cases
│   ├── Performance Metrics
│   └── Issues Found
│
└── FEEDBACK_LOG.md (Team Feedback)
    ├── Sprint Reviews
    ├── Suggestions
    ├── Changes Made
    └── Follow-up Actions
```

### 6.2 Definition of Done für Tests

```
Für jeden Test-Case gelten folgende DoD-Kriterien:

☑ Testfall hat klares Ziel und Beschreibung
☑ Preconditions sind definiert
☑ Input-Daten sind spezifiziert
☑ Expected Output ist messbar definiert
☑ Test ist reproduzierbar (deterministisch)
☑ Automatisierte Assertions existieren
☑ Test ist dokumentiert
☑ Code Review durchgeführt
☑ Test erfolgreich ausgeführt
☑ Keine Abhängigkeiten zu anderen Tests
☑ Test läuft in < 5 Sekunden (Unit Tests)
☑ Test läuft in < 30 Sekunden (Integration Tests)
```

---

## 7. Review & Feedback Process

### 7.1 Initial Review Checklist

**Für Team-Review vorbereiten:**

```
□ Test Strategy Dokument vollständig
□ Alle Features analysiert
□ Test-Ziele klar definiert
□ Test-Klassifikation logisch
□ Coverage-Kriterien realistisch
□ Prioritisierung nachvollziehbar
□ AI Metriken messbar
□ Ressourcen-Planung realistisch (Zeit/Personal)

Dokument-Qualität:
□ Sprache ist konsistent (Deutsch/English)
□ Beispiele sind konkret und nachvollziehbar
□ Tabellen sind korrekt formatiert
□ Links zu Code funktionieren
□ Keine Rechtschreibfehler
□ Struktur ist logisch
```

### 7.2 Team Review Fragen

**Entwicklungs-Team sollte sich folgende Fragen stellen:**

1. **Feature Coverage**
   - "Sind alle wichtigen Features abgedeckt?"
   - "Fehlen neue Features in der Analyse?"
   - "Sind die Test-Ziele realistisch?"

2. **Practical Feasibility**
   - "Können diese Tests mit unseren Tools implementiert werden?"
   - "Haben wir genug Zeit für alle Tests?"
   - "Benötigen wir zusätzliche Test-Infrastruktur?"

3. **Priority Agreement**
   - "Stimmen wir mit der Priorisierung überein?"
   - "Sollten wir andere Dinge zuerst testen?"
   - "Ist die Test-Reihenfolge sinnvoll?"

4. **Metrics Agreement**
   - "Sind diese Metriken messbar?"
   - "Sind die Zielwerte realistisch?"
   - "Haben wir Tools zum Messen?"

5. **Risk Management**
   - "Welche Risiken haben wir übersehen?"
   - "Wo könnten Tests scheitern?"
   - "Brauchen wir Fallback-Pläne?"

### 7.3 Feedback Integration

```
Feedback-Prozess:

1. Team-Meeting organisieren
   ↓
2. Strategy präsentieren (30 min)
   ↓
3. Diskussion & Fragen (30 min)
   ↓
4. Feedback sammeln auf Feedback-Template
   ↓
5. Issues & Suggestions dokumentieren
   ↓
6. Strategy überarbeiten basierend auf Feedback
   ↓
7. Überarbeitete Version dem Team zeigen
   ↓
8. Approval einholen
   ↓
9. Dokumentation aktualisieren
   ↓
10. Test-Implementierung beginnen
```

### 7.4 Feedback-Template

**Für Team-Mitglieder zum Ausfüllen:**

```markdown
## Test Strategy Feedback Form

**Reviewer:** [Name]  
**Datum:** [Datum]  
**Rolle:** [Developer/QA/Manager]

### 1. Allgemeine Eindrücke
- [ ] Strategy ist klar und verständlich
- [ ] Strategy ist vollständig
- [ ] Strategy ist realistisch

**Kommentar:** [Text]

### 2. Feature Analysis
Fehlen Features oder Aspekte?
**Feedback:** [Text]

### 3. Test Objectives
Sind die Ziele klar und erreichbar?
**Feedback:** [Text]

### 4. Test Classification
Ist die Klassifikation sinnvoll?
**Feedback:** [Text]

### 5. Coverage & Prioritization
Stimmt die Priorisierung?
**Feedback:** [Text]

### 6. Metrics
Sind die Metriken messbar?
**Feedback:** [Text]

### 7. Implementierbarkeit
Können wir diese Tests implementieren?
**Feedback:** [Text]

### 8. Resourcen
Haben wir genug Zeit/Personal?
**Feedback:** [Text]

### 9. Größte Bedenken
Was sind die Top-3 Bedenken?
1. **[Bedenken]**
2. **[Bedenken]**
3. **[Bedenken]**

### 10. Vorschläge zur Verbesserung
**Vorschläge:** [Text]

### Übersicht
- **Gesamt-Rating:** ☆☆☆☆☆ / 5
- **Genehmigung:** ☐ Ja ☐ Nein (mit Bedingungen) ☐ Nein
```

---

## 8. Iteration & Updates

### 8.1 Versionskontrolle

```
Strategy Version History:

v1.0 (10. Dez 2025)
- Initiale Erstellung
- Feature-Analyse durchgeführt
- Test-Objectives definiert
- Test Classification Model erstellt
- Coverage & Prioritization Rules definiert
- AI Metriken definiert

[Weitere Versionen werden hier dokumentiert]
```

### 8.2 Update Trigger

**Strategy wird aktualisiert wenn:**
- ✏️ Neue Features werden hinzugefügt
- ✏️ Game-Design ändert sich
- ✏️ Team-Feedback angewendet werden muss
- ✏️ Neue Test-Tools verfügbar
- ✏️ Performance-Targets ändern sich

### 8.3 Continuous Improvement

```
Feedback Loop:

Sprint-Ende
    ↓
Test-Ergebnisse analysieren
    ↓
Was funktionierte gut?
Was funktionierte nicht?
    ↓
Strategy überarbeiten
    ↓
Neue Metriken oder Test-Cases hinzufügen
    ↓
Nächster Sprint
```

---

## 9. Appendix: Test Tools & Setup

### 9.1 Empfohlene Tools
- **GDScript Test Framework**: GUT (Godot Unit Testing Framework)
- **Profiler**: Godot built-in Profiler
- **Debugger**: GDScript Debugger (VS Code / Godot Editor)
- **Version Control**: Git mit GitHub
- **Documentation**: Markdown (GitHub Wiki)

### 9.2 Test Environment Setup
- Godot 4.5+
- Test Scene mit NavMesh-Setup
- Mock-Objekte für isolierte Unit Tests
- Performance-Monitoring aktiviert

### 9.3 Continuous Integration
- GitHub Actions für automatisierte Test-Runs
- Bei jedem Commit: Unit & Integration Tests
- Nightly: Gameplay Tests
- Weekly: Performance Profiling

---

## 10. Sign-Off & Genehmigung

```
Diese Test Strategy wird genehmigt durch:

Teambesprechung: [Datum]
Facilitator: [Name]

Team-Mitglieder Zustimmung:
□ Lead Developer: __________________ Datum: ______
□ Lead Tester: __________________ Datum: ______
□ Tech Lead: __________________ Datum: ______
□ Project Manager: __________________ Datum: ______

Notizen: ____________________________________________
________________________________________________________
```

---

**Dokument Ende**

*Diese Test Strategy wird kontinuierlich überarbeitet basierend auf Team-Feedback und praktischen Erfahrungen.*
