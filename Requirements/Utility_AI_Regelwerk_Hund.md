# Utility AI Regelwerk für Hunde-Bewegung
## Design Dokumentation

**Projekt:** Dog vs Owner Game
**User Story:** As a team, we want to design a theoretical rule set for the dog's Utility AI movement, so that we have a clear concept to implement in the next sprint.
**Version:** 2.0
**Datum:** 17. Jänner 2026
**Status:** Teilweise Implementiert

### Implementierungsstatus-Legende
- ✅ = Vollständig implementiert
- ⚠️ = Teilweise implementiert
- ❌ = Nicht implementiert (geplant)

---

## 1. Einleitung

### 1.1 Zweck
Dieses Dokument definiert das theoretische Regelwerk für die Utility-basierte Künstliche Intelligenz (Utility AI) des Hundes im "Dog vs Owner Game". Das Regelwerk dient als Grundlage für die Implementierung im nächsten Sprint.

### 1.2 Scope
Das Regelwerk umfasst:
- Verfügbare Aktionen des Hundes
- Utility-Berechnungsformeln für jede Aktion
- Entscheidungslogik und Auswahlmechanismus
- Verhaltensmodifikatoren und Persönlichkeitsparameter
- Spezielle Regelungen und Edge Cases

### 1.3 Grundprinzip der Utility AI
Der Hund evaluiert kontinuierlich verschiedene Handlungsoptionen und bewertet diese anhand von Utility-Scores (Wertebereich: 0.0 - 1.0). Die Aktion mit dem höchsten Score wird ausgewählt und ausgeführt. Dieser Ansatz ermöglicht dynamisches, kontextabhängiges Verhalten ohne starre Zustandsmaschinen.

---

## 2. Aktionsdefinitionen

Der Hund verfügt über folgende Aktionen:

| Aktion | Beschreibung | Voraussetzungen | Status |
|--------|--------------|-----------------|--------|
| `EAT_SNACK` | Bewegung zu einem Snack und Verzehr | Snack muss sichtbar und erreichbar sein | ✅ |
| `FLEE_FROM_OWNER` | Flucht vor dem Besitzer | Besitzer in Reichweite | ✅ |
| `POOP` | Strategisches Platzieren eines Haufens | Cooldown muss bereit sein | ❌ |
| `IDLE` | Kurzes Warten/Orientieren | Immer verfügbar | ✅ |
| `DIE` | Spielende durch Tod des Hundes | Todesbedingung erfüllt | ✅ |
| `CARRY_FOOD` | Essen mitnehmen während Flucht | Beim Fressen und hohe Flucht-Utility | ✅ (Bonus)

---

## 3. Utility-Berechnungen

### 3.1 EAT_SNACK Utility ✅

**Zweck:** Bewertet die Attraktivität eines Snacks unter Berücksichtigung von Hunger, Gefahr und Snack-Typ.

**Implementiert in:** `scripts/dog.gd` → `calculate_eat_utility()`

**Formel:**
```
Utility_EAT = Base_Score + Hunger_Faktor + Snack_Wert_Faktor 
              - Distanz_Faktor - Besitzer_Gefahr_Faktor 
              - Leben_Risiko_Faktor

Endergebnis: clamp(Utility_EAT, 0.0, 1.0)
```

**Parameter:**

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `Base_Score` | 0.7 | Grundlegende Attraktivität des Fressens |
| `Hunger_Faktor` | 0.0 - 0.3 | Linear skaliert mit Hunger-Level |

**Snack-Wert Modifikatoren:**
- Hundefutter: +0.2
- Käse: +0.15
- Schokolade: +0.1
- Gift: +0.05

**Distanz-Faktor:**
```
Distanz_Faktor = (Distanz_zum_Snack / Max_Sichtweite) * 0.2
```

**Besitzer-Gefahr-Faktor:** ✅
- Besitzer >= 3 Einheiten entfernt: 0.0 (keine Gefahr)
- Besitzer < 3 Einheiten entfernt: 0.3 (hohe Gefahr, reduziert Utility)

**Leben-Risiko-Faktor:**
- Bei 3 Leben: keine Änderung
- Bei 2 Leben:
  - Schokolade: +0.1 (erhöhte Vorsicht)
  - Gift: +0.0
- Bei 1 Leben:
  - Schokolade: +0.3 (starke Vorsicht)
  - Gift: +0.2 (leichte Vorsicht)

---

### 3.2 FLEE_FROM_OWNER Utility ✅

**Zweck:** Bewertet die Notwendigkeit, vor dem Besitzer zu fliehen.

**Implementiert in:** `scripts/dog.gd` → `calculate_flee_utility()`

**Formel:**
```
Utility_FLEE = Base_Score + Bedrohungs_Faktor + Fress_Schutz_Faktor 
               - Snack_Opportunitäts_Faktor

Endergebnis: clamp(Utility_FLEE, 0.0, 1.0)
```

**Parameter:**

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `Base_Score` | 0.3 | Grundlegende Fluchtneigung |

**Bedrohungs-Faktor:** ✅
- Distanz < 2 Einheiten: +0.5
- Distanz 2-4 Einheiten: +0.2
- ❌ Besitzer bewegt sich aktiv auf Hund zu: +0.2 (nicht implementiert)

**Fress-Schutz-Faktor:**
- Hund ist aktuell am Fressen: +0.4

**Snack-Opportunitäts-Faktor:**
- Sicherer Snack in Nähe (> 5 Einheiten vom Besitzer): +0.2

---

### 3.3 POOP Utility ❌

**Status:** Nicht implementiert - geplant für zukünftige Version

**Zweck:** Bewertet die strategische Platzierung eines Haufens zur Behinderung des Besitzers.

**Formel:**
```
Utility_POOP = Base_Score + Strategischer_Positions_Faktor 
               - Redundanz_Faktor

Endergebnis: clamp(Utility_POOP, 0.0, 1.0)

Falls Cooldown nicht bereit: Utility_POOP = 0.0
```

**Parameter:**

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `Base_Score` | 0.2 | Grundlegende Neigung |
| `Cooldown` | 15-20 Sek | Zufälliger Cooldown zwischen Nutzungen |

**Strategischer-Positions-Faktor:**
- Besitzer verfolgt aktiv: +0.3
- Vorhersage: Besitzer wird diesen Weg nehmen: +0.2
- Position zwischen Hund und mehreren Snacks: +0.15

**Redundanz-Faktor:**
- Bereits Haufen in < 3 Einheiten Nähe: +0.5

---

### 3.4 IDLE Utility ✅

**Zweck:** Ermöglicht dem Hund kurze Pausen zur Neuorientierung.

**Implementiert in:** `scripts/dog.gd` → `calculate_idle_utility()`

**Formel:**
```
Utility_IDLE = Base_Score + Orientierungs_Faktor + Disziplin_Faktor

Endergebnis: clamp(Utility_IDLE, 0.0, 1.0)
```

**Parameter:**

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `Base_Score` | 0.1 | Niedrige Grundpriorität |

**Orientierungs-Faktor:**
- Keine klaren Handlungsoptionen: +0.2

**Disziplin-Faktor:**
- Gerade diszipliniert worden (< 2 Sekunden): +0.3

---

### 3.5 DIE Action ✅

**Zweck:** Repräsentiert das Spielende durch Tod des Hundes. Dies ist keine bewusste Entscheidung der AI, sondern ein erzwungener Zustand.

**Implementiert in:** `scripts/dog.gd` → `die()`

**Auslösende Bedingungen:**

| Bedingung | Beschreibung |
|-----------|--------------|
| Gift gefressen | Sofortiger Tod beim Verzehr von Gift |
| 3x Schokolade | Tod nach dem dritten Schokoladen-Verzehr |
| 0 Leben | Leben-Counter erreicht 0 |

**Verhalten:**
```
Utility_DIE = Nicht anwendbar (erzwungener Zustand)

Wenn Todesbedingung erfüllt:
  1. Stoppe alle laufenden Aktionen
  2. Spiele Tod-Animation
  3. Triggere Game-Over-Zustand
  4. Deaktiviere alle weiteren AI-Updates
```

**Spezialfälle:**
- **Gift:** Keine 1,5 Sekunden Fresszeit - sofortiger Tod beim Betreten
- **Schokolade:** Nach 3. Verzehr wird Leben auf 0 gesetzt → Tod
- **Disziplinierung vor Gift:** Kann Tod verhindern (außer bereits begonnen zu fressen)

**Integration in Entscheidungslogik:**
```
Vor jeder Aktionsauswahl:
  IF Leben <= 0 OR Gift_gerade_gefressen:
    FORCE DIE
    RETURN
  
  // Normale Utility-Berechnung fortsetzten
```

---

## 4. Verhaltensmodifikatoren ❌

**Status:** Persönlichkeitsparameter und Schwierigkeitsgrade sind nicht implementiert.

### 4.1 Persönlichkeitsparameter ❌

Die KI des Hundes kann durch folgende Parameter charakterisiert werden:

| Parameter | Wertebereich | Einfluss |
|-----------|--------------|----------|
| `risk_taking` | 0.0 - 1.0 | Beeinflusst die Bewertung gefährlicher Snacks (Schokolade, Gift) |
| `greediness` | 0.0 - 1.0 | Multipliziert EAT_SNACK Utility-Scores |
| `cleverness` | 0.0 - 1.0 | Verbessert POOP-Platzierung und Gift-Erkennung |
| `obedience` | 0.0 - 1.0 | Reduziert alle Aktionen wenn Besitzer in der Nähe ist |

**Anwendung der Parameter:**
```
Final_Utility_EAT = Utility_EAT * (1.0 + greediness * 0.3)
Final_Utility_EAT = Final_Utility_EAT * (1.0 - obedience * Besitzer_Nähe_Faktor)

Gift_Wert = Base_Gift_Wert * (1.0 - cleverness * 0.5)
Schokolade_Wert = Base_Schokolade_Wert * (1.0 + risk_taking * 0.2)
```

### 4.2 Schwierigkeitsgrade ❌

Verschiedene Hunde-Charaktere mit unterschiedlichen Persönlichkeitsprofilen:

**Easy Dog (Anfänger-Modus):**
```
risk_taking: 0.2
greediness: 0.4
cleverness: 0.3
obedience: 0.7
```

**Medium Dog (Normal-Modus):**
```
risk_taking: 0.5
greediness: 0.6
cleverness: 0.6
obedience: 0.4
```

**Hard Dog (Experten-Modus):**
```
risk_taking: 0.7
greediness: 0.8
cleverness: 0.9
obedience: 0.2
```

---

## 5. Entscheidungslogik ✅

**Implementiert in:** `scripts/dog.gd` → `_physics_process()`, `evaluate_and_choose_action()`

### 5.1 Haupt-Update-Schleife

Die KI durchläuft pro Update-Zyklus folgende Schritte:

```
1. Todes-Check (höchste Priorität)
   - Prüfe ob Leben <= 0
   - Prüfe ob Gift gefressen wurde
   - Falls ja: Erzwinge DIE und beende Update-Schleife

2. Zustandsupdate
   - Aktualisiere Hunger (+0.01 pro Sekunde)
   - Aktualisiere Cooldowns
   - Aktualisiere Lerneffekte (Disziplin-Counter Verfall: -1 alle 60 Sekunden)
   - Aktualisiere kurzfristige Lern-Timer

3. Umgebungsanalyse
   - Scanne alle sichtbaren Snacks
   - Bestimme Position des Besitzers
   - Bestimme Geschwindigkeit und Richtung des Besitzers
   - Identifiziere Hindernisse und Haufen

4. Utility-Berechnung
   - Für jeden sichtbaren Snack: Berechne EAT_SNACK(snack)
   - Berechne FLEE_FROM_OWNER
   - Berechne POOP (falls Cooldown bereit)
   - Berechne IDLE

5. Aktionsauswahl
   - Wähle Aktion mit höchstem Utility-Score
   - Bei Gleichstand: Zufällige Auswahl

6. Ausführung
   - Starte Pathfinding (falls Bewegung erforderlich)
   - Führe Aktion aus
   - Setze entsprechende Cooldowns
   - Aktualisiere Leben-Counter (falls Snack gefressen)
```

### 5.2 Update-Frequenz

| Update-Typ | Frequenz | Beschreibung |
|------------|----------|--------------|
| Utility-Berechnung | 0.2 - 0.5 Sekunden | Hauptentscheidungsschleife |
| Zustandsupdate | Jeden Frame | Hunger, Cooldowns, Positionen |
| Pathfinding-Update | 0.1 Sekunden | Navigation und Wegfindung |

---

## 6. Spezielle Regelungen

### 6.1 Anti-Stuck Mechanismus ✅

**Implementiert in:** `scripts/dog.gd` → `execute_eat_snack()`

**Problem:** Hund könnte in Entscheidungsschleife stecken bleiben.

**Aktuelle Implementierung:**
- Stuck-Detection: Wenn Hund < 0.5 Einheiten in 5 Sekunden bewegt → Ziel aufgeben
- Konstanten im Code:
  - `STUCK_TIMEOUT = 5.0` Sekunden
  - `STUCK_DISTANCE_THRESHOLD = 0.5` Einheiten
- Wenn `nav_agent.is_target_reachable()` false → sofort aufgeben

**Ursprüngliche Planung (nicht vollständig implementiert):**
- ❌ Wenn Hund 3 Sekunden lang keine neue Aktion ausführt → Erzwinge IDLE
- ✅ Wenn Pfad zu gewähltem Ziel blockiert → Wähle zweitbeste Aktion
- ❌ Nach 5 Sekunden IDLE → Erzwinge Zufallsbewegung

### 6.2 Lerneffekt nach Disziplinierung (Erweitertes System) ⚠️

**Implementiert in:** `scripts/dog.gd` → `on_disciplined()`, `calculate_eat_utility()`

**Status:** Teilweise implementiert - Basis-Lernsystem funktioniert, aber nicht alle Features.

Das Lernsystem basiert auf wiederholter Disziplinierung und ermöglicht es dem Hund, bestimmte Snacks dauerhaft zu meiden.

#### 6.2.1 Disziplin-Counter pro Snack-Typ ✅

Jeder Snack-Typ hat einen eigenen Disziplin-Counter:

```gdscript
# Aktuelle Implementierung in dog.gd:
var discipline_counts: Array[int] = [0, 0, 0, 0]  # DOG_FOOD, CHEESE, CHOCOLATE, POISON
@export var discipline_threshold_block := 3
@export var discipline_penalty_per_count: float = 0.25
```

**Erhöhung des Counters:** ✅
- +1 wenn Hund diszipliniert wird (egal ob unterwegs oder beim Essen)
- Maximum: 3 (discipline_threshold_block)

**Verfall des Counters:** ❌
- Nicht implementiert - Counter bleibt permanent
- Geplant: -1 alle 60 Sekunden (langsames Vergessen)

#### 6.2.2 Auswirkungen auf Snack-Attraktivität ⚠️

**Kurzfristiges Lernen (nach einzelner Disziplinierung):** ❌
```
Nicht implementiert!
Geplant: 10 Sekunden Timer mit -0.2 Modifier
```

**Progressives Lernen (nach mehrfacher Disziplinierung):** ✅

**Aktuelle Implementierung (vereinfacht):**
| Disziplin-Counter | Utility-Modifier | Beschreibung |
|-------------------|------------------|--------------|
| 0 | 0.0 | Normales Verhalten |
| 1 | -0.25 | Leichte Vorsicht |
| 2 | -0.50 | Deutliche Vorsicht |
| 3 | BLOCKED | Snack wird komplett ignoriert |

**Ursprüngliche Planung (nicht implementiert):**
| Disziplin-Counter | Utility-Modifier | Beschreibung |
|-------------------|------------------|--------------|
| 0 | +0.0 | Keine Disziplinierung - normales Verhalten |
| 1 | -0.15 | Leichte Vorsicht |
| 2 | -0.35 | Deutliche Vorsicht |
| 3+ | -0.60 | Starke Vermeidung (praktisch keine Attraktivität mehr) |

**Aktuelle Formel im Code:**
```gdscript
# In calculate_eat_utility():
if is_snack_blocked(snack_type):
    return 0.0  # Komplett blockiert bei 3 Disziplinierungen

var count := discipline_counts[snack_type]
var discipline_penalty := float(count) * discipline_penalty_per_count  # 0.25 pro Count
utility -= discipline_penalty
```

#### 6.2.3 Spezialfälle ❌

**Status:** Spezialfälle für verschiedene Snack-Typen sind nicht implementiert. Alle Snacks werden gleich behandelt.

**Geplant - Schokolade (3x diszipliniert):**
```
IF Disziplin_Counter["Schokolade"] >= 3:
  // Schokolade wird praktisch nicht mehr angerührt
  Schokolade_Utility = Base_Utility * 0.1 - 0.6
  // Dies führt typischerweise zu Utility ≈ 0.0
```

**Geplant - Gift (permanentes Lernen):**
```
// Gift-Disziplinierung hat stärkere Wirkung
IF Disziplin_Counter["Gift"] >= 1:
  Gift_Utility_Modifier = -0.8 (permanent für Spielsitzung)

// Gift wird nie vergessen (kein Verfall des Counters)
```

**Geplant - Hundefutter (positive Verstärkung):**
```
// Hundefutter-Disziplinierung ist weniger effektiv
Hundefutter_Modifier = Progressiv_Modifier * 0.5
```

#### 6.2.4 Cleverness-Einfluss auf Lernen ❌

**Status:** Nicht implementiert - Persönlichkeitsparameter existieren nicht.

Der Persönlichkeitsparameter `cleverness` beeinflusst die Lerngeschwindigkeit:

```
// Intelligentere Hunde lernen schneller
Effektiver_Counter = Disziplin_Counter * (1.0 + cleverness * 0.5)

Beispiel:
- Dummer Hund (cleverness=0.3): Benötigt 3 echte Disziplinierungen
- Schlauer Hund (cleverness=0.9): Benötigt ~2 echte Disziplinierungen
                                    (3 * 1.45 ≈ 4.35 effektiv)
```

#### 6.2.5 Visualisierung für Spieler

**Empfohlene UI-Indikatoren:**
- Anzahl der Disziplinierungen pro Snack-Typ im HUD
- Visuelle Warnung beim Hund (z.B. Fragezeichen) bei Snacks mit Counter ≥ 2
- "Gelernt"-Symbol bei Snacks mit Counter ≥ 3

#### 6.2.6 Beispiel-Szenario

**Situation:** Hund hat Schokolade 3x fast gefressen und wurde jedes Mal diszipliniert

```
Disziplin_Counter["Schokolade"] = 3

Neue Schokolade spawnt:
Base_Utility = 0.7 + 0.15 (Hunger) + 0.1 (Snack-Wert) - 0.03 (Distanz) = 0.92
Progressiv_Modifier = -0.60
Final_Utility = 0.92 - 0.60 = 0.32

Zum Vergleich - Käse (nie diszipliniert):
Final_Utility = 0.87 (keine Modifier)

Ergebnis: Hund bevorzugt jetzt stark Käse über Schokolade!

Nach weiteren 3 Minuten (3x Verfall):
Disziplin_Counter["Schokolade"] = 0
→ Hund "vergisst" langsam und könnte wieder Schokolade probieren
```

### 6.3 Hunger-System ⚠️

**Implementiert in:** `scripts/dog.gd` → `update_hunger()`, Konstanten am Dateianfang

**Hunger-Mechanik:**
```gdscript
# Aktuelle Konstanten:
const HUNGER_INCREASE_PER_SEC: float = 0.01
const HUNGER_REDUCTION_PER_SNACK: float = 0.3
```

**Was implementiert ist:** ✅
- Hunger_Level: 0.0 - 1.0
- Anstieg: +0.01 pro Sekunde
- Reduktion: -0.3 pro gegessenem Snack
- Hunger beeinflusst EAT_SNACK Utility: `hunger * 0.3` (linear)

**Was NICHT implementiert ist:** ❌
Die gestaffelten Hunger-Schwellenwerte:
```
Geplant (nicht implementiert):
- Bei Hunger < 0.3: Normales Verhalten
- Bei Hunger 0.3 - 0.7: +0.15 auf alle EAT_SNACK Utilities
- Bei Hunger > 0.7: +0.3 auf alle EAT_SNACK Utilities, -0.2 auf FLEE
```

### 6.4 Pathfinding-Integration

**Algorithmus:** A* oder Navmesh-basiert

**Berücksichtigung:**
- Snacks als temporäre Hindernisse (außer Ziel-Snack)
- Haufen als No-Go-Zonen für den Hund
- Besitzer-Position als dynamisches Hindernis bei FLEE

**Performance:**
- Maximale Pfadlänge: 20 Einheiten
- Bei unerreichbarem Ziel: Utility = 0.0

---

## 6.5 Bonus-Features (nicht im Original-Regelwerk) ✅

Die folgenden Features wurden während der Implementierung hinzugefügt:

### 6.5.1 Food Carrying (Essen mitnehmen)

**Implementiert in:** `scripts/dog.gd` → `finish_carried_food()`, `update_carrying_food_visual()`

Wenn der Hund beim Fressen durch hohe Flucht-Utility (> 0.6) unterbrochen wird, nimmt er das Essen mit:

```gdscript
# Konstanten:
const FINISH_CARRIED_FOOD_DELAY: float = 3.0  # Sekunden bis Essen fertig

# Variablen:
var carrying_food: bool = false
var carried_snack_type: int = -1
var carrying_food_timer: float = 0.0
```

**Ablauf:**
1. Hund frisst (is_eating = true)
2. Spieler nähert sich → Flucht-Utility > 0.6
3. Hund unterbricht Fressen, nimmt Essen mit (carrying_food = true)
4. Nach 3 Sekunden Flucht: Essen wird "fertig gegessen"
5. Snack-Effekte werden angewendet (Hunger-Reduktion, Chocolate-Counter, etc.)

**Visuell:** Kleines Snack-Modell am `FoodCarrierMarker` Node des Hundes.

### 6.5.2 Disziplin-Pause

**Implementiert in:** `scripts/dog.gd` → `on_disciplined()`

```gdscript
const DISCIPLINE_PAUSE_DURATION: float = 2.0  # Sekunden Pause nach Disziplinierung
```

Nach Disziplinierung pausiert der Hund für 2 Sekunden und spielt eine "beschämte" Animation.

---

## 7. Implementierungs-Empfehlungen

### 7.1 Architektur-Vorschlag

```
UtilityAI_Controller
├── ActionEvaluator
│   ├── EatSnackEvaluator
│   ├── FleeEvaluator
│   ├── PoopEvaluator
│   ├── IdleEvaluator
│   └── DieHandler (erzwungener Zustand)
├── EnvironmentScanner
├── PersonalityProfile
├── DisciplineLearningSystem
│   ├── DisciplineCounters (pro Snack-Typ)
│   ├── ShortTermMemory (10-Sekunden-Timer)
│   └── UtilityModifierCalculator
└── ActionExecutor
```

### 7.2 Debug-Tools

Empfohlene Visualisierungen für Entwicklung:
- Anzeige aller aktuellen Utility-Scores über dem Hund
- Farbliche Markierung des gewählten Snacks
- Visualisierung der Besitzer-Gefahrenzone
- Anzeige des aktuellen Hunger-Levels
- **Disziplin-Counter Display:** Zeige Counter-Werte für jeden Snack-Typ
- **Lern-Fortschritt:** Visuelle Indikatoren wenn Counter-Schwellenwerte erreicht werden (1, 2, 3+)

### 7.3 Testing-Szenarien

| Szenario | Erwartetes Verhalten |
|----------|---------------------|
| Snack nahe, Besitzer fern | Hund geht zu Snack |
| Snack nahe, Besitzer sehr nahe | Hund flieht |
| Niedriges Leben, Schokolade verfügbar | Hund meidet Schokolade |
| Besitzer verfolgt aktiv | Hund nutzt POOP strategisch |
| Kein Snack verfügbar | Hund geht in IDLE |
| Gift wird betreten | Sofortiger Tod (DIE) |
| 3. Schokolade gefressen | Tod nach Verzehr (DIE) |
| Disziplinierung vor Gift-Verzehr | Tod wird verhindert |
| Schokolade 3x diszipliniert | Hund meidet Schokolade dauerhaft |
| Nach 3 Minuten ohne Disziplinierung | Hund vergisst langsam (Counter-Verfall) |
| Cleverer Hund, 2x diszipliniert | Lernt schneller als dummer Hund |

---

## 8. Offene Fragen und zukünftige Erweiterungen

### 8.1 Offene Fragen für Implementierung
- Exakte Größe der Map und Einheiten
- Maximale Anzahl gleichzeitiger Snacks
- Visuelle Indikatoren für Spieler (Hund-Absicht sichtbar?)

### 8.2 Mögliche Erweiterungen
- Kooperative Verhaltensweisen (bei Multi-Dog-Modus)
- Erweiterte Pathfinding-Strategien (Täuschungsmanöver)
- Dynamische Schwierigkeitsanpassung basierend auf Spieler-Performance
- Emotional States (Angst, Freude) die Utility-Berechnungen beeinflussen

---

## 9. Glossar

| Begriff | Definition |
|---------|------------|
| Utility Score | Numerischer Wert (0.0-1.0), der die Attraktivität einer Aktion repräsentiert |
| Clamp | Begrenzung eines Wertes auf einen definierten Bereich |
| Cooldown | Wartezeit bis eine Aktion erneut verfügbar ist |
| Pathfinding | Algorithmus zur Wegfindung von A nach B |
| Navmesh | Navigation Mesh - vereinfachte Darstellung begehbarer Flächen |
| Disziplin-Counter | Zähler der Disziplinierungen pro Snack-Typ für Lerneffekt |
| Progressives Lernen | Verstärktes Lernen durch wiederholte Disziplinierung |
| Counter-Verfall | Langsames "Vergessen" durch Reduzierung der Counter über Zeit |

---

## 10. Versionierung

| Version | Datum | Änderungen | Autor |
|---------|-------|------------|-------|
| 1.0 | 24.10.2025 | Initiales Regelwerk erstellt | Team |
| 2.0 | 17.01.2026 | Implementierungsstatus aktualisiert, Code-Referenzen hinzugefügt, Bonus-Features dokumentiert | Team |

---

## 11. Anhang

### 11.1 Beispiel-Berechnung

**Szenario:** Hund (2 Leben, Hunger: 0.5) sieht Schokolade in 3 Einheiten Entfernung, Besitzer ist 2 Einheiten entfernt.

**Fall A: Keine vorherige Disziplinierung**
```
EAT_SNACK (Schokolade):
Base_Score = 0.7
Hunger_Faktor = 0.5 * 0.3 = 0.15
Snack_Wert = 0.1
Distanz_Faktor = (3 / 20) * 0.2 = 0.03
Besitzer_Gefahr = 0.3 (Besitzer < 3 Einheiten)
Leben_Risiko = 0.1 (2 Leben, Schokolade)
Disziplin_Modifier = 0.0 (Counter = 0)

Utility_EAT = 0.7 + 0.15 + 0.1 - 0.03 - 0.3 - 0.1 + 0.0 = 0.52

FLEE_FROM_OWNER:
Base_Score = 0.3
Bedrohung = 0.5 (< 2 Einheiten)
Fress_Schutz = 0.0 (nicht am Fressen)

Utility_FLEE = 0.3 + 0.5 = 0.8

Ergebnis: FLEE_FROM_OWNER wird gewählt (0.8 > 0.52)
```

**Fall B: Schokolade wurde 3x diszipliniert**
```
EAT_SNACK (Schokolade):
Base_Score = 0.7
Hunger_Faktor = 0.15
Snack_Wert = 0.1
Distanz_Faktor = 0.03
Besitzer_Gefahr = 0.3
Leben_Risiko = 0.1
Disziplin_Modifier = -0.60 (Counter = 3)

Utility_EAT = 0.7 + 0.15 + 0.1 - 0.03 - 0.3 - 0.1 - 0.60 = -0.08
Utility_EAT (clamped) = 0.0

FLEE_FROM_OWNER:
Utility_FLEE = 0.8 (unverändert)

Ergebnis: FLEE_FROM_OWNER wird gewählt (0.8 > 0.0)
→ Selbst wenn Besitzer weit weg wäre, würde Hund Schokolade ignorieren!
```

**Fall C: Käse (nie diszipliniert) vs. Schokolade (3x diszipliniert)**
```
Beide Snacks in gleicher Entfernung, Besitzer weit weg:

EAT_SNACK (Käse):
Utility = 0.7 + 0.15 + 0.15 - 0.03 + 0.0 = 0.97

EAT_SNACK (Schokolade):
Utility = 0.7 + 0.15 + 0.1 - 0.03 - 0.60 = 0.32

Ergebnis: Hund wählt Käse (0.97 > 0.32)
```

---

**Ende des Dokuments**
