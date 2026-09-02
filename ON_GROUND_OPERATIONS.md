# On-Ground Farm Operations — A Guide for Developers & Agents

**Purpose of this document:** Every screen, field, and validation rule in this system exists because of something that physically happens on a farm. If you don't know what actually happens at 7:00 AM in a poultry shed, you will build the wrong form. This document exists so that anyone writing code, designing a schema, or reasoning about this system as an AI agent has a concrete mental picture of the physical reality behind every data point.

This is **not** a feature spec. It does not describe screens, APIs, or database fields. It describes the farm itself — the birds, the sheds, the people, and the physical sequence of work. Cross-reference this with `architecture.md` for how each physical event becomes a data record.

---

## 1. The Physical Setup

### 1.1 What a "Farm" actually is
A farm is a physical piece of land with:
- Several **sheds** (long, low buildings), each housing one flock of birds
- Usually one **feed mill** on-site (not every farm has one) that grinds and mixes raw materials into finished feed
- Storage areas: raw material godowns (maize, soya, minerals), finished feed silos, vaccine cold storage (fridge/cold box)
- A water source and delivery system to each shed
- Basic staff facilities

Four farms in this operation are geographically separate — two in the same district, two in different districts. This matters physically: a supervisor on Farm 3 cannot walk over and check something on Farm 1. Each farm runs as an independent physical unit day-to-day, even though data eventually consolidates centrally.

### 1.2 What a "Shed" actually is
A shed is a single building holding one batch of birds of the same age, placed on the same day. Sheds have:
- A fixed **capacity** — a hard physical ceiling. You cannot put more birds in than the shed's floor space, feeders, and drinkers can support. Overcrowding causes heat stress, disease spread, and pecking.
- **Feeders** — either manual trough-feeders (someone walks the length of the shed pouring feed) or mechanized chain/pan feeders. The `feeder_type` on a shed record isn't decorative — it changes how feed wastage happens and how long feeding takes.
- **Drinkers** — nipple lines or bell drinkers, supplied from an overhead tank or direct line.
- **Nest boxes** (for layer sheds) — where hens are supposed to lay. Eggs laid on the floor ("floor eggs") are dirtier, more likely to break, and worth less — this is why floor eggs are tracked as a separate number, not folded into "eggs collected."
- Lighting — layers need controlled light hours to sustain lay; this is a physical input the system has visibility into only via alerts, not direct control.

### 1.3 What a "Flock" physically is
A flock is a specific batch of birds of one breed, placed in one shed on one day, that lives, ages, produces, and eventually leaves as one cohort. Physically:
- Chicks arrive by truck from a hatchery on placement day. Someone counts them (or trusts the hatchery's count) as they're unloaded — this is `initial_birds_placed`. Some chicks are already dead in the box on arrival — this is `dead_on_arrival`, and it's the hatchery's problem, not the farm's, which is why it's tracked separately for supplier accountability.
- From that day, the flock ages one day at a time. Its physical needs change completely as it ages: a day-old chick needs 32°C brooding heat and starter crumbs; a 110-day-old layer needs layer mash and nest boxes. The system's "lifecycle stage" isn't an abstraction — it corresponds to physically different feed, physically different housing setup, and physically different daily tasks.
- A flock ends when it's fully depleted (sold off, typically as spent hens after the lay cycle ends) or in rare cases condemned (disease).

---

## 2. Who Physically Does the Work

### 2.1 The Supervisor
This is the person physically inside the shed every day. On a mid-size layer farm, a supervisor's day involves genuine manual labor, not just data entry:
- Walking the length of each shed, visually checking birds for lethargy, unusual posture, respiratory sounds, or clustering (a sign of cold stress or illness)
- Physically picking up and counting dead birds each morning — this is unpleasant, time-pressured work usually done before it gets hot
- Manually or mechanically distributing feed
- Walking nest boxes and floor to collect eggs, often multiple passes a day to prevent breakage and contamination
- Administering vaccines — this can mean mixing vaccine into drinking water tanks, giving individual eye-drops, or manual injections bird-by-bird depending on vaccine type
- Physically checking feed stock levels in the shed (a visual/physical measure, often "how full is the bin" rather than a scale reading)
- Handling feed bags — receiving them from mill dispatch, checking bag count and weight against what was sent

A farm typically has **multiple supervisors** sharing coverage of all sheds on that farm — any of them may report for any shed. This is why every submission requires a typed name: the system has no other way to know who physically did the work that day.

### 2.2 The Owner
The owner is generally **not physically present** at any single farm most days. Their physical involvement is different in kind:
- Occasional physical farm visits, especially when an alert says something is wrong
- Direct phone/WhatsApp conversations with an external vet (the vet is never in the system directly — see 2.3)
- Physical or verbal approval of decisions supervisors can't make: shed depletion, vaccine schedule overrides, discrepancy investigations

### 2.3 The Vet
Vets are external professionals, not farm staff. Physically, a vet interaction usually looks like: supervisor notices something wrong → calls/WhatsApps the owner → owner calls the vet → vet may visit physically to examine sick birds, or may advise remotely based on the owner's description and photos → owner enters the vet's recommendation into the system afterward. The vet never touches the software.

---

## 3. The Physical Daily Timeline

This is what actually happens, roughly in this order, in a working layer shed. Times are indicative, not fixed — real farms shift based on weather, season, and labor availability.

| Approx. Time | Physical Activity | Why it happens at this time |
|---|---|---|
| Early morning (before/at sunrise) | Supervisor walks each shed, physically searches for and removes dead birds found overnight | Birds die overnight more than daytime; carcasses must be removed before heat, scavengers, or disease spread. This is also when the previous day's feed stock is checked. |
| ~7:00 AM | Feed received/checked at shed, feeders topped up | Birds are hungriest first thing; feed access first thing in the morning strongly affects daily intake |
| ~7:30 AM | Feed dispatch physically confirmed — bags/quantity received at shed matched against what mill sent | Feed leaves the mill by trolley/vehicle; the person receiving at the shed must physically verify quantity matches, catching spillage or short-loading immediately, not days later |
| Mid-morning | Water lines checked, nest boxes checked | Water interruption is often the earliest visible sign of a bigger problem (pump failure, blockage) |
| As required (per vaccine schedule) | Vaccine administered — water-based mixed into drinking supply, or individual eye-drop/injection depending on vaccine | Some vaccines require water withdrawal for 1-2 hours beforehand so birds are thirsty enough to consume vaccinated water fully; this is a real physical prerequisite step, not a system delay |
| Midday–early afternoon | Egg collection round(s) — walking nest boxes, physically gathering eggs into trays/crates | Multiple collections per day reduce breakage, reduce contamination from birds standing on eggs, and catch floor-laid eggs before they're soiled further |
| Afternoon | Feed mill operations (if the farm has a mill) — raw materials weighed, mixed per formula, batch produced, sample checked for quality | Feed is usually produced in batches to be dispatched the same or next day — it isn't stockpiled indefinitely due to quality/freshness concerns |
| Evening | Closing feed stock physically measured (how much is left in the shed bin) | This single number lets the system back-calculate the day's actual consumption — supervisors are never asked to calculate, only to look and report what remains |
| Evening | Second egg collection pass (if applicable) | Prevents overnight breakage/soiling of afternoon-laid eggs |
| Ongoing | Environmental observation — shed temperature, unusual behavior, unusual smell/ammonia buildup | These are physical senses (sight, smell, sound) a supervisor uses that no sensor currently replaces |

Everything on this table happens **regardless of whether the app is working**. Offline-first isn't a technical nicety — a supervisor with no signal still has to feed birds, collect eggs, and remove the dead. The system's job is to catch up with reality once connectivity returns, never to gate the physical work on connectivity.

---

## 4. Physical Processes Behind Each Data Point

### 4.1 Mortality
Physically: a dead bird is found on the shed floor, picked up, and removed. The supervisor makes a *visual* judgment about probable cause (was it obviously injured? did it look like a respiratory case — gasping, discharge? was it a normal-looking bird with no visible cause?) — this is why cause tracking is a **dropdown categorization**, not a diagnosis. Supervisors are not vets and are explicitly not expected to diagnose. A "post-mortem" (physically cutting open a bird to look at internal organs) is only done occasionally, usually when the owner or vet asks for it after unusual mortality.

**Culled sick birds** are a physically distinct action from mortality: a bird that is clearly very sick but still alive is deliberately removed from the flock (and typically humanely destroyed) to prevent disease spread or suffering. This is a *decision*, not a discovery, which is why it's tracked separately from birds simply found dead.

### 4.2 Egg Production
Physically: eggs are gathered from nest boxes (clean, intended location) and from the floor (birds that laid outside the box — dirtier, more likely to be cracked, sometimes eaten by other birds before collection). At the point of collection, the supervisor visually sorts: intact and clean (saleable), visibly cracked/broken, and floor eggs. This sorting happens with the eggs physically in hand — it is fast, visual, and happens naturally during collection, which is why the system asks for exactly these three numbers and calculates everything else.

### 4.3 Feed — Mill to Bird
This is a physical chain with multiple real transfer points, each of which is a place things can physically go wrong:
1. **Raw materials arrive** at the farm (maize, soya meal, minerals, etc.) by truck, are weighed, and stored.
2. **Batch production**: at the mill, workers weigh out raw materials per the formula and run them through a mixer. A physical sample may be checked (color, smell, texture) as a rough quality check before the batch is approved for use.
3. **Dispatch**: finished feed is loaded (bags or bulk) and physically transported to sheds — sometimes by hand-cart within a farm, sometimes by vehicle between distant sheds.
4. **Receipt at shed**: the supervisor at the shed physically checks what arrived against what was supposedly sent. A mismatch here is either spillage in transit, a counting error, or in rare cases pilferage — the system flags variance so a human can investigate.
5. **Feeding out**: feed is manually or mechanically placed into feeders. Some feed is unavoidably wasted (spilled, fouled) — this is invisible to the system except as it shows up in higher-than-expected feed-per-bird numbers.
6. **Closing stock check**: at day's end, the supervisor looks at what's left in the shed's feed storage. This is a physical, visual/weighed measurement, and it's the *only* feed number that requires any real "measurement effort" from the supervisor — everything else is either counted (bags/kg dispatched) or calculated.

### 4.4 Vaccine Administration
Physically, this varies a lot by vaccine type:
- **Drinking water vaccines**: water supply is often shut off for 1-2 hours before dosing so birds are thirsty and will drink the medicated water quickly and fully. The vaccine is mixed into a measured water volume, sometimes with a skim-milk powder stabilizer, and distributed through the drinker lines. Timing and water shut-off are real physical constraints — get it wrong and birds under-consume the dose.
- **Eye-drop**: physically catching and dosing birds one by one (or a sample, depending on flock size and vaccine) — labor-intensive, used for smaller-volume, higher-precision vaccines.
- **Injection**: individual bird handling, needle and syringe, typically for specific vaccine types or boosters.
- **Spray**: fine mist over day-old chicks, often at the hatchery or immediately on arrival.

Cold chain matters physically: vaccines are temperature-sensitive (typically 2–8°C) and are transported/stored in cold boxes or a fridge. A vaccine left out too long in farm heat is physically compromised — this is why storage temperature fields exist, and why "administered" is a distinct, locked event from "scheduled."

### 4.5 Bird Movements (Sales, Transfers, Losses)
- **Sold**: a buyer physically arrives (often for spent hens at end-of-lay, or culled birds), birds are counted and loaded onto their vehicle.
- **Transferred**: birds are physically moved from one farm's shed to another farm's shed — this happens for reasons like rebalancing shed capacity or consolidating small flocks. There is a real time gap between birds leaving one farm and arriving at another (travel time), which is why transfer-out and transfer-in are two separate, paired physical events, not one instantaneous one.
- **Missing/Theft suspected**: the supervisor does a physical bird count reconciliation and cannot account for the discrepancy. This is inherently uncertain — the supervisor is reporting an absence, not a witnessed event, which is why owner approval and pattern-watching exist around this category specifically.

---

## 5. Physical Realities That Shape the System's Design

A few things about the physical environment that explain design decisions you'll see elsewhere in this project:

- **Connectivity is genuinely unreliable** at some farms (especially the ones in different districts). This isn't a hypothetical edge case — it's an everyday operating condition. Any workflow that assumes constant connectivity will fail in actual use.
- **Supervisors are not data analysts.** They observe and report; they do not calculate ratios, percentages, or trends. Every design decision that asks a supervisor to enter a raw count instead of a calculated figure is intentional and should not be "simplified" by pushing calculation onto them.
- **Physical labor is time-constrained.** A supervisor covering multiple sheds has limited minutes per shed per round. Any data entry step that takes meaningfully long, or requires typing rather than tapping, competes directly with actual animal care time. This is why fast entry (under 60 seconds for vaccine reporting, under 45 seconds for egg entry) is a hard design constraint, not a nice-to-have.
- **The physical bird count is the foundation of everything.** HDP%, feed-per-bird, mortality rate — every metric divides by the live bird count. If the physical count is wrong (a movement wasn't recorded, a death wasn't logged), every derived number for that flock is wrong from that point forward. This is why bird movements require owner approval before affecting the live count — it's a deliberate checkpoint against an error propagating silently through the whole system.
- **Physical isolation between farms is real, not just a database partition.** A supervisor at Farm 3 has no way to know what's happening at Farm 1 beyond what the app tells them, and shouldn't — this maps directly to the permission model (supervisors see only their assigned farm).

---

## 6. Glossary (Farm Terms Developers May Not Know)

| Term | Physical Meaning |
|---|---|
| HDP (Hen-Day Production) | Percentage of live hens that laid an egg that day — the core layer productivity metric |
| DOA | Dead on Arrival — chicks already dead when the hatchery delivery is unloaded |
| Brooding | The early-life period (first ~1 week) requiring supplemental heat, since chicks can't yet regulate their own body temperature |
| FCR / Feed-per-egg | How much feed it physically takes to produce one saleable egg — the core feed efficiency measure |
| Culling | Deliberate removal of a visibly sick (but alive) bird from the flock |
| Withdrawal (water) | Temporarily cutting water supply before a water-based vaccine, so birds fully consume it when it's reintroduced |
| Cold chain | The unbroken chain of refrigerated storage/transport a vaccine needs to remain effective |
| Spent hens | Layers past their economical production life, typically sold off at flock depletion |
| Litter | The floor bedding material in a shed (rice husk, wood shavings, etc.) |
| Biosecurity | Physical practices (foot dips, restricted entry, cleaning between flocks) that prevent disease introduction/spread |

---

*This document should be read alongside `architecture.md` (system design) and updated whenever a physical process on the farm changes — e.g., a farm switches from manual to mechanized feeders, or adds a new vaccine delivery method. If the physical reality changes and this document doesn't, the system will drift from what it's actually supposed to model.*
