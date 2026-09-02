??  POULTRY FARM
COMMAND CENTER
Master System Architecture — v3.0

Operation	4 Farms  |  Own Feed Mills  |  5,00,000 + Layer Birds

Roles	Owner  +  Supervisor  (two roles only)

Priority	Vaccine Integrity ? Egg Production ? Feed Efficiency ? Mortality

Design Date	2025




Section 0 — Design Principles
These principles are non-negotiable. Every feature, every screen, every alert in this system must satisfy all six.

??  Offline First, Always
Every farm app must function without internet. Data queues locally and syncs when connectivity resumes.
A network outage must never stop a supervisor from entering data or viewing their task list.

???  The Owner Wakes Up Knowing
Before the owner makes a single phone call, the dashboard shows the state of all four farms.
What is wrong. What is at risk. What needs a decision today.

??  Supervisors Report Reality — System Interprets It
Supervisors do not calculate, analyse, or decide. They report what happened.
The system does everything else: validation, calculation, correlation, alerting.

??  No Isolated Data
Every entry connects to at least two other modules.
Feed ? Flock ? Production ? Health. Nothing exists in a silo.

??  Bad Data is Stopped at Entry
Validation happens the moment a supervisor submits a figure.
An impossible number never reaches the database. A suspicious number is flagged before acceptance.

??  Every Decision is Permanently Recorded
Who decided. When. Why. This applies to vaccine overrides, schedule changes, formula edits, and all owner approvals.
The system is a permanent operational ledger, not just a live dashboard.


Section 1 — Role Architecture
1.1  Two Roles Only
The system has exactly two user roles. This is a deliberate design decision to match the real management structure of the operation. No additional roles will be created unless the operation fundamentally changes.

OWNER	SUPERVISOR
• Full access — all four farms
• Final approval on all decisions
• Only role that can change templates,
  formulas, and vaccine schedules
• Receives all critical alerts
• Enters vet recommendations
• Manages users
• Creates new flock placements	• Access to their assigned farm only
• Can report for ANY shed on their farm
• Multiple supervisors per farm —
  any of them can submit any shed entry
• Writes name on every submission
• Cannot approve or override anything
• Cannot see other farms
• Receives own-farm alerts only

1.2  Supervisor Accountability — Name-Based Reporting
Because multiple supervisors share farm-wide access, every submission requires the supervisor to type their name. The system also silently records their login ID. This gives two accountability layers without restricting flexibility.

??  Two-Layer Accountability
Layer 1 — Login ID: Automatically recorded on every submission (system-level, immutable)
Layer 2 — Reported-by Name: Supervisor types their name when submitting (visible on all records)
After submission: a one-tap confirmation screen locks the entry to the supervisor's session.
This prevents "I didn't enter that" disputes without adding workflow complexity.

1.3  Vet Interactions — No System Login Required
External vets communicate with the owner directly by phone or WhatsApp, exactly as today. The owner then enters vet recommendations into the system as health events. The vet's name and advice are permanently recorded without the vet ever needing a system account. If an in-house vet is employed in the future, a supervisor account is created for them.

1.4  Complete Permission Matrix

Capability	Owner	Supervisor
View all farms (consolidated)	? Full access	? Not visible
View own farm	? Full access	? Full access
Daily shed entry (morning + eve)	?	?
Vaccine reporting	?	?
Feed mill batch entry	?	?
Raw material receipt entry	?	?
Flag health issue	?	?
View production dashboard	? All farms	? Own farm
Receive alerts	? All farms	? Own farm only
Enter vet recommendation	? Owner only	?
Approve any system override	? Owner only	?
Vaccine schedule changes	? Owner only	?
Vaccine template edits	? Owner only	?
Feed formula edits	? Owner only	?
Export operational data	? Owner only	?
User management	? Owner only	?
Flock placement / depletion	? Owner only	?


Section 2 — System Topology
2.1  Four-Farm Distributed Architecture
Farms 1 and 2 are in the same district. Farms 3 and 4 are in different districts. Internet reliability varies. The architecture is designed so that each farm operates independently and syncs to a central cloud when connectivity is available.

OWNER DASHBOARD  (Web + Mobile — consolidated, all farms)
         |  reads from
CENTRAL CLOUD SERVER
Data warehouse  ·  Intelligence engine  ·  Alert dispatcher
Master templates  ·  User management  ·  Report generator
    |sync         |sync          |sync        |sync
   FARM 1       FARM 2        FARM 3      FARM 4
  Local DB     Local DB      Local DB    Local DB
  Mill+Sheds   Mill+Sheds    Mill+Sheds  Mill+Sheds
  District A   District A    District B  District C

2.2  Sync Strategy

Data Path	Frequency	When Offline
Supervisor ? Local Farm Server	Real-time over local WiFi	Works normally — no internet needed
Local Farm Server ? Cloud	Every 15 minutes	Queued locally, syncs on reconnect
Cloud ? Owner Dashboard	Live	Shows last known state with timestamp
Cloud ? Supervisor App	On app open + every 30 min	Cached task list used offline

2.3  Conflict Resolution
•Daily entries: last-write-wins (only one supervisor should be entering a shed at a given time)
•Master data conflicts (template edits, formula changes): require owner re-approval if sync collision detected
•Vaccine schedule: locked during owner approval workflow — no parallel edits allowed


Section 3 — Module Overview
The system is organised into 13 modules across four layers. No module operates in isolation — every module reads from and writes to the shared daily flock snapshot.

#	Module	Responsibility
A	Flock Management	Placement, stages, bird count, lifecycle
B	Vaccine Scheduling	Templates, scheduling, conflicts, execution, reporting
C	Feed Mill & Production	Batch production, formula versioning, quality control
D	Feed Dispatch & Consumption	Dispatch tracking, consumption, efficiency
E	Egg Production & Quality	Daily collection, HDP, anomaly detection
F	Mortality & Health	Daily mortality, cause tracking, health events
G	Raw Material Inventory	Stock levels, consumption, reorder alerts
H	Vaccine Inventory	Stock, expiry, procurement alerts
I	Intelligence Engine	Anomaly detection, pattern recognition, recommendations
J	Alert Dispatcher	Routing, WhatsApp, in-app, escalation
K	Owner Dashboard	Morning command screen, drill-down views
L	Supervisor App	Daily task flow, offline-first, validation
M	Data Export	Operational data export for external verification
N	Bird Movement Tracking	All non-mortality bird departures and arrivals — live count integrity

3.1  Module Interaction Map
The Daily Flock Snapshot is the central record that connects all operational modules. Every morning entry, every vaccine event, every feed dispatch, and every egg collection ultimately updates or reads from this record.

                   +---------------------+
    PLACEMENT ----?¦    FLOCK  CORE  (A)  ¦?---- BREED MASTER
                   +---------------------+
                              ¦  is hub for
         +--------------------+----------------------+
         ?                    ?                      ?
  +------------+    +------------------+   +--------------+
  ¦ VACCINE(B) ¦    ¦ FEED MILL (C)    ¦   ¦  EGG PROD(E) ¦
  +------------+    +------------------+   +--------------+
        ¦                    ¦                     ¦
        ¦           +--------?---------+          ¦
        ¦           ¦ FEED DISPATCH (D) ¦          ¦
        ¦           +-------------------+          ¦
        +--------------------?---------------------+
                   +---------------------+
                   ¦  DAILY FLOCK        ¦
                   ¦  SNAPSHOT  ?--------¦ MORTALITY (F)
                   +---------------------+
                              ¦
                   +----------?----------+
                   ¦  INTELLIGENCE (I)   ¦
                   ¦  ALERT ENGINE  (J)  ¦
                   +---------------------+
                              ¦
                   +----------?----------+
                   ¦  OWNER DASHBOARD(K) ¦
                   +---------------------+


Section 4 — Master Data Layer
Master data is set once and rarely changed. It is the foundation everything else runs on. Only the Owner can create or edit master data.
4.1  Company & Farm Registry
Entity	Key Fields	Notes
COMPANY	company_id, name, owner_contact, whatsapp_number	Single record
FARM	farm_id, name, district, state, manager_name, has_feed_mill, gps_coords	One record per farm
SHED	shed_id, farm_id, shed_number, capacity_birds, shed_type, feeder_type, is_active	Capacity is a hard ceiling — no overstocking allowed

4.2  Breed Master
The standard_hdp_curve is the most important field. It stores expected production % for every day of lay. The intelligence engine uses this to calculate variance daily — not a flat benchmark but an age-adjusted curve.

Field	Type	Purpose
breed_id, breed_name	Text	BV-380, Lohmann Brown, etc.
expected_lay_start_day	Integer	Auto-calculates production phase start
peak_hdp_percent, peak_hdp_day	Decimal, Integer	Benchmark for flock performance ranking
standard_hdp_curve	JSON array	Day-by-day expected HDP% for entire lay period
standard_mortality_rate_percent	Decimal	Normal daily mortality by stage
standard_feed_per_bird_g	JSON (by stage)	Expected feed intake benchmark

4.3  Vaccine Master
The conflict_group field is the engine of vaccine conflict detection. All vaccines in the same group (e.g., Group-A = live virus) cannot overlap within their minimum gap window.

Field	Example
vaccine_id, vaccine_name	Ranikhet Lasota
disease_target	Newcastle Disease
vaccine_type	Live / Killed / Toxoid / Recombinant
conflict_group	Group-A (Live Virus)  |  Group-B (Killed)  |  Group-C (Other)
min_gap_before_days, min_gap_after_days	5 days before  |  5 days after
default_method, default_dose_ml_per_bird	Drinking Water  |  0.03 ml
storage_temp_min_c, storage_temp_max_c	2°C to 8°C
notes_for_worker	Withdraw water 2 hrs before dosing (plain language)

4.4  Vaccine Schedule Templates
Each breed has one active template. Templates are versioned — edits create a new version, old version is archived. Active flocks are not auto-updated when a template changes; the owner decides which active flocks adopt the new template.

4.5  Feed Formula Library
Formula versions are permanent. Every feed batch produced stamps the formula version at time of production. If a formula is edited later, batches already produced are unaffected — their version is locked. This allows retrospective analysis: "What formula were these birds eating when production dropped?"

4.6  User Registry
Field	Notes
user_id, full_name	Auto-generated ID
phone_number	Used for WhatsApp alerts (owner) and login
role	OWNER or SUPERVISOR — nothing else
assigned_farm_id	Supervisors locked to one farm. Owner: null (sees all).
pin_code	4-digit PIN for app login — no passwords for supervisors
language_preference	Hindi / Bengali / English — app displays in chosen language
is_active	Deactivate without deleting — preserves historical records


Section 5 — Module A: Flock Management
5.1  Lifecycle Stages (Auto-Calculated)

Stage	Age (Days)	Auto-Triggers	Key Metric
Brooding	0 – 6	Chick feed formula activated	Survival rate
Grower	7 – 42	Grower formula switch	Weight gain (optional)
Pre-Layer	43 – 105	Pre-layer formula, lighting check alert	Uniformity
Layer	106+	Layer formula, HDP tracking begins	HDP %, Feed/Egg ratio

5.2  Flock Placement — Key Fields
Placement date and initial bird count are locked after 24 hours. Everything downstream — vaccine schedule, stage transitions, feed benchmarks, HDP curves — is calculated from these two locked values.

Field	Behaviour
flock_id	Auto: F-[FARM CODE]-[YEAR]-[SEQ], e.g. F-F1-2025-047
placement_date	Locked after 24 hrs — drives all age calculations
initial_birds_placed	Locked after 24 hrs — permanent denominator
dead_on_arrival	Separate from farm mortality — tracked for supplier quality analysis
net_birds_started	Auto: placed minus DOA — starting live count
vaccine_template_id	Selected at placement — auto-generates full schedule
flock_status	active / depleted / sold / condemned

5.3  Daily Flock Snapshot — The Central Record
One record per flock per day. This is the heartbeat of the entire system. Every module reads from or writes to this record. The intelligence engine runs its analysis against the accumulated history of these snapshots.

Field Group	Fields	Entry Method
Identity	flock_id, farm_id, shed_id, snapshot_date, bird_age_days, flock_stage	Auto-populated
Bird Count	opening_bird_count, mortality_count, culled_sick_count, other_movements_count, arrivals_count, closing_bird_count	Opening auto; mortality+culled entered; other_movements+arrivals auto from approved movement records; closing auto: opening - mortality - culled - other + arrivals
Feed	feed_batch_id, feed_issued_kg, feed_returned_kg, feed_net_kg, feed_per_bird_g, expected_per_bird_g, variance_g	Batch auto from dispatch; issued+returned entered; rest auto
Eggs	eggs_collected, eggs_broken, eggs_floor, eggs_saleable, hdp_percent, hdp_expected, hdp_variance	Collected+broken+floor entered; rest auto
Water	water_consumed_litres	Entered (strongly recommended — earliest health signal)
Environment	morning_temp_c, evening_temp_c, observations	Optional but valuable for anomaly context
Accountability	entry_by (login ID), reported_by_name, entry_timestamp, sync_status	Login auto; name typed by supervisor
Validation	validated, validation_flags, manager_reviewed	Auto-flagged by system; owner reviews flagged entries


Section 6 — Module B: Vaccine Scheduling & Execution
6.1  Two Vaccine Tracks

Track 1 — Pre-Scheduled (Age-Based)	Track 2 — Emergency / As-Required
Generated automatically at flock placement
Based on breed template and placement date
Full schedule visible from Day 1
Alert cascade: T-7, T-3, T-0, overdue	Raised by: disease outbreak, mortality spike, vet advice
Entered by Owner only (after vet communication)
Triggers conflict engine immediately
Requires owner approval before schedule updates

6.2  Vaccine Event Status Lifecycle

Status	Trigger	Action
SCHEDULED	Auto-generated at placement	Visible in schedule, no alert yet
UPCOMING	T-7 days before target	Notification to supervisor
DUE SOON	T-3 days before target	Yellow alert to supervisor
DUE TODAY	Target date reached	Red alert + task assigned to supervisor
ADMINISTERED	Supervisor reports completion	Record locked, 7-day watch period starts
OVERDUE	T+1 day, not reported	Alert escalates to owner
CRITICALLY OVERDUE	T+3 days, not reported	WhatsApp to owner, immunity risk flagged
RESCHEDULED	Owner moves date after conflict	Original date preserved, approval recorded
SKIPPED	Owner approves non-administration	Permanent record, reason mandatory

6.3  Conflict Detection & Resolution
When an emergency vaccine is added, the conflict engine scans ±14 days of the schedule for every affected flock. It checks conflict groups and minimum gaps, identifies all clashes, scores resolution options by disruption level, and presents them to the owner. The owner selects or customises. The system then cascades the approved changes through all subsequent events, re-checking each for new conflicts.

??  Conflict Engine Rules
Vaccines in the same conflict group cannot be given within their minimum gap of each other.
System suggests least-disruptive option first (fewest downstream changes, all within flexibility windows).
Owner can override any suggestion — but must provide a reason if outside the safe window.
All overrides are permanently recorded: who, when, why, what the system recommended.
Cascade recalculation runs after every approved change until the full schedule is conflict-free.

6.4  Supervisor Vaccine Reporting — App Flow
Designed for completion in under 60 seconds. Supervisor selects the vaccine task, taps MARK AS DONE, and fills in four fields. Everything else is auto-populated. If done on a different date, a reason dropdown appears. One-tap confirmation locks the record.

Field	Entry Method
Date administered	Pre-filled: today. Tap DIFFERENT DATE to change — triggers reason dropdown
Batch number	Barcode scan (preferred) or typed — validates against vaccine inventory
Method used	Large-button selection: Water / Injection / Eye Drop / Spray
Birds covered	Pre-selected: ALL BIRDS. Tap PARTIAL to enter count manually
Reason for delay	Dropdown appears only if date differs from target: Stock late / Birds unwell / Equipment / Staff / Other
Observations	Optional free text — anything unusual noted during administration

6.5  Post-Vaccine Monitoring
After every vaccine administration, the intelligence engine automatically watches the flock for the defined watch period (typically 7 days). Any anomaly in mortality or production during this window is tagged "post-vaccine period" rather than flagged as an unexplained event. This prevents false alarms for expected post-vaccination dips while still detecting genuine problems.

6.6  Vaccine Inventory
Each farm tracks its own vaccine stock separately. Alerts fire when doses remaining fall below 120% of what is needed for the next scheduled event, or when expiry is within 30 days with stock remaining. This prevents the most dangerous operational failure: running out of vaccine before a scheduled dose.


Section 7 — Module C: Feed Mill & Production
7.1  Feed Batch Production Record
Every batch produced at every farm mill is recorded. The formula version is stamped at production time and is immutable — even if the formula is later edited, this batch record retains the version that was in use when it was produced.

Field	Notes
batch_id	Auto: FM-[FARM CODE]-[DATE]-[SEQ], e.g. FM-F1-20250414-003
formula_id + version	Stamped at production — immutable after save
quantity_produced_kg	Entered by supervisor at mill
quality_check_status	Pass / Fail / Conditional — entered by supervisor
storage_location	Which silo or store — enables traceability to dispatch
remaining_qty_kg	Auto-decremented as batches are dispatched to sheds

7.2  Ingredient Recording
For each batch, the actual quantity of every ingredient used is recorded. If the actual weight differs from the formula specification by more than 2%, the system flags it and requires a reason. This protects feed quality integrity and creates a raw material consumption trail.

7.3  Quality Failure Handling

Status	System Action	Who Can Release
PASS	Batch available for dispatch immediately	No release needed
CONDITIONAL	Batch dispatched with warning flag. All receiving sheds tagged. Intelligence engine watches production for 14 days.	Owner approves before dispatch
FAIL	Batch quarantined — cannot be dispatched. Owner notified immediately.	Owner decides: Reprocess / Discard / Sell off-farm


Section 8 — Module D: Feed Dispatch & Consumption
8.1  Feed Dispatch Record
Feed is tracked from mill to shed. Dispatch is recorded when it leaves the mill. Receipt is confirmed by the supervisor at the shed. Any discrepancy between dispatched and received quantity is flagged as a potential spillage or pilferage event.

Field	Notes
batch_id	Which mill batch — links feed to formula version
to_shed_id + flock_id	Auto-links to active flock in that shed
quantity_dispatched_kg	Entered at mill by supervisor
quantity_received_kg	Confirmed at shed by supervisor — must match within 1%
dispatch_variance_kg	Auto-calculated — recurring variance flags investigation

8.2  Daily Consumption Calculation
Supervisors enter one number at end of day: closing feed stock remaining in the shed. The system calculates net consumption from what was dispatched minus what remains. Workers never calculate — they only measure what is left.

??  Feed Efficiency Metric
Feed per Egg (g) = Total feed consumed ÷ Saleable eggs produced
Standard benchmark for layer flocks: 120–145g per egg (varies by flock age)
Tracked daily, 7-day rolling average, and flock-lifetime average.
Deterioration trend (3+ days rising above 160g) triggers investigation alert.


Section 9 — Module E: Egg Production & Quality
9.1  Daily Egg Entry
Designed for completion in under 45 seconds. Three numbers entered. Everything else calculated automatically. The supervisor sees their shed's HDP after submission — giving them immediate feedback and an opportunity to spot entry errors before the record is finalised.

Field	Entry / Calculation
eggs_collected	ENTERED — total picked up from shed
eggs_broken	ENTERED — cracked or damaged during collection
eggs_floor	ENTERED — laid outside nest boxes, soiled
eggs_saleable	AUTO — collected minus broken minus floor
hdp_percent	AUTO — (saleable ÷ live birds) × 100
hdp_expected	AUTO — from breed curve for today's bird age
hdp_variance_percent	AUTO — actual minus expected
eggs_per_bird_week	AUTO — 7-day rolling average

9.2  Production Anomaly Detection

Level	Trigger	Who is Notified	How
INFO	HDP 3–5% below expected for current age	Supervisor (in-app)	In-app notification
WARNING	HDP drops >5% vs previous day  OR  broken eggs >2% of collected	Supervisor + Owner	In-app + push notification
ALERT	HDP drops >10% in 48 hrs  OR  HDP >15% below breed curve	Owner	In-app + SMS
CRITICAL	HDP drops >20% in 72 hrs  OR  multiple flocks same farm dropping simultaneously	Owner	WhatsApp + SMS + in-app

9.3  Automatic Cause Investigation
When a production anomaly is flagged at WARNING level or above, the intelligence engine runs a cross-module investigation and delivers a report to the owner. The report checks: vaccine events in the past 7 days, feed batch changes in the past 14 days, mortality trends, flock age vs breed curve. Each factor is assessed and the system states whether it explains, partially explains, or does not explain the drop. No manual correlation required.

9.4  Flock Production Milestones
Key milestones are auto-detected and permanently recorded: first egg date, 50% production date, peak HDP date, peak HDP percentage, weeks above 90%, natural decline start. These milestones feed breed benchmarking — after multiple flocks, the system builds performance norms specific to your farms, not just manufacturer standards.


Section 10 — Module F: Mortality & Health Tracking
10.1  Daily Mortality Entry
Mortality is the farm's most sensitive real-time health signal. Entry is two fields: count of dead birds and optional cause selection from a dropdown. Supervisors do not diagnose — they categorise. Over time, cause data reveals seasonal patterns and farm-specific vulnerabilities.

Field	Notes
mortality_count	Dead birds found — entered each morning
culled_count	Sick birds removed alive — tracked separately from mortality
cause_breakdown	Dropdown multi-select: Unknown / Injury / Respiratory / Digestive / Prolapse / Heat stress / Other
post_mortem_done	Yes/No — if yes, findings entered as free text
vet_consult_needed	Flag raised by supervisor — escalates to owner automatically

10.2  Mortality Alert Thresholds

Level	Trigger	Who is Notified	How
INFO	Actual rate > 1.2× expected for current stage	Supervisor	In-app flag on dashboard
WARNING	Actual rate > 1.5× expected  OR  3-day upward trend	Supervisor + Owner	In-app + push
ALERT	Actual rate > 2× expected  OR  sudden same-day spike	Owner	In-app + SMS
CRITICAL	Rate > 3× expected  OR  multiple sheds spiking simultaneously on same farm	Owner	WhatsApp + SMS + in-app

10.3  Health Event Log
Beyond daily mortality counts, discrete health events are recorded: disease suspicion, injury outbreaks, nutritional deficiencies, environmental stress, vet consultation outcomes. Each health event links to any vaccine or treatment it triggered. This creates a complete clinical history for every flock that supports retrospective diagnosis and farm biosecurity review.


Section 11 — Modules G & H: Inventory Management
11.1  Raw Material Inventory (Module G)
Each farm tracks its own raw material stock. Stock is auto-decremented when a feed batch is produced. Supervisors enter purchase receipts. The system calculates days of stock remaining based on the 14-day average consumption rate.

Alert Level	Trigger	Action
Procurement Reminder	14 days of stock remaining	In-app notification to supervisor
Order Needed	7 days of stock remaining	Alert to owner
Urgent	3 days of stock remaining	WhatsApp to owner — production at risk
Critical	1 day of stock remaining	WhatsApp + SMS — mill must pause if not resolved
Cross-Farm Surplus	Farm A has excess, Farm B critical	System suggests inter-farm transfer

11.2  Vaccine Inventory (Module H)
Each farm tracks vaccine stock: vials on hand, doses per vial, expiry dates, cold chain confirmation on receipt. The system calculates whether current stock is sufficient for the next scheduled event plus a 20% buffer. If insufficient, a procurement alert fires immediately — not on the day of the vaccine.


Section 12 — Intelligence Layer
12.1  Anomaly Detection Engine
Runs every time a daily snapshot is submitted. Checks data integrity first, then flags anomalies.

Check	Validation Rule
Bird count integrity	Opening minus mortality minus culled must equal closing. Any discrepancy blocked.
Mortality range	Mortality count checked against expected range for breed and stage.
Feed plausibility	Feed/bird must be within ±30% of expected for stage. Outside = flag.
Feed arithmetic	Issued minus returned must equal consumed. Mismatch blocked.
Egg arithmetic	Collected = saleable + broken + floor. Mismatch blocked.
HDP plausibility	HDP must be between 0% and 105%. Outside range is rejected.
Batch consistency	Feed batch dispatched to this shed must match what supervisor confirms.
Cross-module tagging	Vaccine in last 7 days? Feed batch change in last 14? Health event active? All tagged on snapshot.

??  Validation Philosophy
Impossible numbers are REJECTED — arithmetic errors that cannot be true (e.g., broken + floor > total collected).
Suspicious numbers are FLAGGED — values outside expected ranges. Supervisor sees warning and must confirm.
Confirmed suspicions go to owner review queue — the owner sees flagged entries separately each morning.
This means bad data is caught at the point of entry, not discovered weeks later during analysis.

12.2  Pattern Recognition Engine
Runs nightly on all historical data across all farms. Identifies patterns that no daily alert would catch because each individual data point looks normal. Examples of patterns detected:

•Feed per bird rising 2–3g per day for 12 consecutive days — not explained by stage change — possible feeder wastage
•Two adjacent sheds on the same farm showing respiratory mortality on the same days across multiple flocks — possible structural or biosecurity issue
•BV-380 flocks on Farm 2 consistently peaking 4 days later than breed standard — possible lighting schedule or feed transition timing issue
•Raw material costs per kg of feed produced are 8% higher on Farm 3 vs Farm 1 for the same formula — procurement pricing review needed
•Mortality spikes on Farm 4 every December–January — seasonal cold stress pattern — proactive intervention opportunity

12.3  Alert Dispatcher (Module J)

Level	Trigger	Who is Notified	How
INFO	Routine observation, no action needed	Supervisor (own farm)	In-app dashboard flag
WARNING	Anomaly detected, supervisor can handle	Supervisor + Owner	In-app + push notification
ALERT	Problem confirmed, owner awareness needed	Owner	In-app + SMS
CRITICAL	Immediate owner decision required	Owner directly	WhatsApp + SMS + in-app siren

Alert discipline: The system is deliberately designed to escalate to the owner only when a genuine decision is required. Supervisors handle INFO and most WARNING flags. The owner's WhatsApp is reserved for CRITICAL events only — ensuring that when the owner's phone alerts, it means something real.


Section 13 — Dashboards & Reporting
13.1  Owner Morning Dashboard
The single most important screen in the system. Answers five questions before the owner makes a single phone call: What is broken? Which vaccines are due? Which flock is underperforming? Where is feed efficiency slipping? What needs my decision today?

??  FARM COMMAND CENTER                   Mon, 14 Apr 2025  6:47 AM
----------------------------------------------------------------
  TOTAL LIVE BIRDS: 5,12,840     ACTIVE FLOCKS: 28     FARMS: 4
----------------------------------------------------------------
  ?? NEEDS YOUR ATTENTION (3)     YESTERDAY ACROSS ALL FARMS
  ---------------------------------------------------------
  ?? Vaccine OVERDUE +1 day       Eggs Collected :  4,41,280
     F-038, F-041, Farm 2         Saleable       :  4,37,190 (99.1%)
  ??  Production drop >10%        Overall HDP    :  85.3%  ? -0.4%
     F-051, Farm 3                vs Breed Target:  87.1%  ? -1.8%
  ??  Maize stock Farm 4: 4 days  Feed Consumed  :  61,200 kg
  ---------------------------------------------------------
  FLOCK PERFORMANCE RANKING
  ?? F-047  Farm1 Sh3  Day187   91.2%  ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ?
  ?? F-039  Farm1 Sh7  Day201   89.4%  ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦   ?
  ?? F-051  Farm3 Sh5  Day134   76.3%  ¦¦¦¦¦¦¦¦¦¦¦¦      ??
  ?? F-038  Farm2 Sh2  Day168   68.1%  ¦¦¦¦¦¦¦¦¦¦¦       ??
  ---------------------------------------------------------
  Farm1: ? Normal   Farm2: ?? Vaccine overdue   Farm3: ?? Prod drop   Farm4: ?? Stock low

13.2  Dashboard Drill-Down Hierarchy

Level	Screen	Contents
Level 1	Command Dashboard	All farms summary, all critical alerts, flock ranking
Level 2	Farm View	All sheds on selected farm, farm-level metrics, vaccine calendar
Level 3	Flock Detail	7-day production, feed, mortality trend + system investigation report
Level 4	Event Detail	Full record of specific alert — vaccine, anomaly, health event
Level 5	Decision Screen	Owner approves, overrides, or schedules — action recorded permanently

13.3  Supervisor App — Daily Workflow
The supervisor app is a task list, not a menu system. When a supervisor opens the app, they see their farm's pending tasks for today, ordered by urgency. They work through the list. When all tasks are done, the farm is considered reported for the day.

Time	Task	Entry Required
7:00 AM	Morning Entry	Deaths found, feed remaining yesterday, feed received today
7:30 AM	Feed Dispatch Confirm	Confirm kg received matches dispatch record
As needed	Vaccine Administration	Batch, method, coverage, date, observations
2:30 PM	Egg Collection Entry	Total collected, broken, floor eggs
5:00 PM	Closing Feed Stock	Remaining feed in shed (closing stock)
Mill (any time)	Feed Batch Production	Batch qty, formula used, quality check, ingredient weights
As needed	Raw Material Receipt	Material, quantity, supplier, lot number
As needed	Bird Movement Report	Report missing / sold / transferred birds — owner approves before count updates


Section 14 — Module N: Bird Movement Tracking
This module was added to address a critical gap in the original design. Any bird that leaves or enters a flock for a reason other than daily mortality must be recorded here. The live bird count is the denominator of every metric in this system — HDP, feed per bird, mortality rate. If it is wrong, everything calculated from it is wrong.

??  Core Purpose — One Reason Only
This module exists solely to keep the live bird count accurate.
It is not an accounting tool. No sale prices. No financial records.
Every non-mortality departure must have a reason so the count stays honest and traceable.

14.1  Movement Types

Movement Type	Direction	Who Initiates	Approval Required
MORTALITY	OUT	Supervisor — daily	None — part of daily routine entry
CULLED_SICK	OUT	Supervisor — daily	None — part of daily routine entry
SOLD	OUT	Supervisor reports	Owner approves count before live total updates
TRANSFERRED_OUT	OUT	Supervisor reports	Owner approves — auto creates paired TRANSFER_IN
CONDEMNED	OUT	Supervisor reports	Owner approves before count updates
THEFT_SUSPECTED	OUT	Supervisor reports	Owner approves — triggers repeat-pattern watch
MISSING_UNKNOWN	OUT	Supervisor reports	Owner approves — triggers repeat-pattern watch
TRANSFER_IN	IN	Auto — paired with TRANSFER_OUT	Confirmed by receiving farm supervisor

14.2  Bird Movement Record — Full Structure
Stripped to only what is needed to keep the count accurate and traceable. No financial fields.

Field	Notes
movement_id	Auto: BM-[FLOCK_ID]-[SEQ], e.g. BM-F047-003
flock_id	FK ? FLOCK
farm_id, shed_id	FK ? FARM, SHED
movement_date	Date the movement occurred
movement_type	ENUM from list above
direction	OUT or IN — auto-set from movement_type
bird_count	How many birds — entered by supervisor
reason_note	Brief free text — optional, plain language
bird_count_before	Auto-pulled from current live count
bird_count_after	Auto-calculated: before ± bird_count
reported_by_name	Supervisor types their name
reported_by_login	Auto — login ID of session
approved_by	Owner user_id — required for all non-mortality types
approval_timestamp	When owner approved
status	PENDING (awaiting owner approval) / APPROVED / REJECTED
sync_status	local / synced — offline-first support

14.3  How Movement Records Connect to the Daily Snapshot
The supervisor never enters other_movements_count manually. The system calculates it automatically from all approved movement records for that flock on that date. This means a supervisor cannot silently remove birds from the count — an approved movement record must exist first.

CLOSING BIRD COUNT FORMULA:

  closing = opening
          - mortality_count          (supervisor enters daily)
          - culled_sick_count         (supervisor enters daily)
          - other_movements_count     (AUTO from approved movement records)
          + arrivals_count            (AUTO from approved transfer-in records)

Every component is either entered by the supervisor directly
or pulled automatically from approved records.
The closing count is never entered — always calculated.

14.4  Approval Workflow
When a supervisor reports any non-mortality bird movement, the record sits in PENDING status. The live count is not yet affected. The owner receives an alert and reviews the count before approving.

OWNER ALERT — Bird Movement Pending Approval
Farm 2  |  Shed 3  |  Flock F-041
Type: MISSING / UNKNOWN
Count: 25 birds
Reported by: Raju Singh  |  6:14 PM
Current live count: 19,847 ? will become 19,822 if approved
[APPROVE]     [QUERY SUPERVISOR]     [REJECT]

14.5  Intelligence Rule — Recurring Loss Pattern

??  Automatic Pattern Detection for Bird Loss
IF THEFT_SUSPECTED or MISSING_UNKNOWN events occur more than 2 times in 30 days on the same farm:
? Owner alert: "Recurring unexplained bird loss on Farm 2. Review shed access and count verification process."
IF TRANSFER_OUT is approved but no matching TRANSFER_IN is confirmed within 24 hours:
? Owner alert: "Transfer of 200 birds from Farm 1 Shed 3 has no confirmed arrival at destination."
These are the only two intelligence rules for this module — lean and directly operational.

14.6  Flock Departure Summary — Always Available
At any time, the owner can pull a complete departure breakdown for any flock. This is a read-only view, not a report that needs to be generated — it is always live.

FLOCK F-047  |  Departure Summary  |  Live view
Placed: 20,000 birds  |  12 Jan 2025
---------------------------------------------
Reason              Count    % of Placed
---------------------------------------------
Mortality             142       0.71%
Culled (sick)          18       0.09%
Sold                  200       1.00%
Transferred out         0       0.00%
Condemned               0       0.00%
Theft suspected        25       0.13%
Missing / Unknown        8       0.04%
---------------------------------------------
Total departed        393       1.97%
Current live       19,607      98.03%


Section 15 — Data Export
No accounting functions exist in this system. Every operational dataset is structured so that it can be exported for external verification when needed. Exports are available on-demand for any date range, any farm, any flock.

Dataset	Contents	Useful For
Feed Consumption by Batch	Batch ID, formula version, dates, kg consumed per flock	Verify feed quantities against purchases
Raw Material Consumption	Material name, quantity per batch, per farm	Verify raw material quantities used
Vaccine Administration Log	Vaccine name, batch, quantity, dates, flocks covered	Verify vaccine quantities used
Egg Production Summary	Saleable eggs by date, farm, flock	Verify against sales records
Mortality + Bird Movement	All departures by type, count, date, flock	Full bird count reconciliation
Flock Lifecycle Summary	Placement to depletion — all operational metrics	Complete flock history in one view

Format: CSV or Excel. Available on-demand for any date range, any farm, any flock. The export structure is consistent — same fields, same order, every time.


Section 16 — Additional Recommended Modules
These modules were not in the original brief but are strongly recommended for an operation at this scale.

??  Flock Depletion & Replacement Planning
When a flock's HDP falls below the configurable economic threshold, the system flags it for depletion review.
Owner approves depletion date. System then calculates: shed cleaning period, downtime, next placement date, chick order lead time.
At 28 active flocks, shed turnover must be systematic — not managed by memory or phone calls.

??  Shed Downtime & Biosecurity Log
Between flocks: records cleanout date, fumigation method, rest period duration, next placement date.
If a new flock has health problems, this log answers: was the shed properly prepared? Was rest period adequate?
Minimum recommended rest period is configurable per farm biosecurity policy.

??  Supplier Performance Tracking
Which hatchery produces highest DOA rates? Which vaccine supplier had a batch with poor efficacy?
Which maize supplier's grain caused feed quality issues? The data already exists in the system.
A supplier performance report view surfaces it — no additional entry required.

??  Water Quality & Supply Tracking
A daily "water supply normal — Yes / No" flag added to morning entry costs 2 seconds.
Water contamination or interruption will destroy production before any other factor.
A monthly water quality test log (pH, TDS, bacterial count) adds retrospective diagnostic power at near-zero data entry cost.


Section 17 — Implementation Sequence
Build in phases. Each phase must be stable and in daily use before the next begins. Do not build everything at once.

Phase	Timeline	What Gets Built	Go-Live Test
1	Weeks 1–8	Master data setup, flock placement, daily snapshot entry, mortality tracking, basic dashboard	All 4 farms entering daily data every day
2	Weeks 9–16	Vaccine template registration, schedule auto-generation, alert system, supervisor vaccine reporting app, conflict engine	Zero missed vaccines across all flocks for 4 weeks
3	Weeks 17–22	Egg production tracking, HDP calculation, breed curve comparison, anomaly detection, production dashboard	Owner gets production report every morning without asking
4	Weeks 23–32	Feed formula library, mill batch production, feed dispatch and consumption, raw material inventory, feed efficiency analytics	Full feed chain traceable from ingredient to egg
5	Weeks 33–40	Cross-module correlation engine, pattern recognition, automated investigation reports, WhatsApp alert integration	System explains production drops before owner asks why
6	Ongoing	Breed benchmarking from own data, supplier performance, flock lifecycle summaries, seasonal pattern analysis	System predicts problems before they fully develop


Section 18 — What This System Is

?  What This Is NOT	?  What This IS
A CRUD data entry application
A generic farm management SaaS product
An accounting or billing system
A system that requires internet to function
A tool that generates reports for reports' sake	A distributed operational command center
A decision-making engine for a 5-lakh bird operation
A permanent operational ledger for your farms
An offline-first system that works in Indian farm conditions
A system that tells you what is wrong before you ask


When this system is fully operational, you will wake up every morning knowing the state of all four farms — not because someone called you, but because the system already told you. You will know which flock is underperforming, why production dropped, whether your vaccines are on schedule, and what decisions only you can make today.

That is the system. That is what you are building.