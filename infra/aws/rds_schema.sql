-- Poultry Farm Command Center — Master Schema v4.0
-- Location: infra/aws/rds_schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- MASTER DATA TABLES
-- ==========================================

-- COMPANY (single row for the enterprise)
CREATE TABLE company (
    company_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    owner_name      VARCHAR(200) NOT NULL,
    owner_phone     VARCHAR(20),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- FARM
CREATE TABLE farm (
    farm_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL REFERENCES company(company_id),
    farm_name       VARCHAR(200) NOT NULL,
    farm_code       VARCHAR(10) NOT NULL UNIQUE,   -- e.g. F1, F2, F3, F4
    district        VARCHAR(100),
    state           VARCHAR(100),
    has_feed_mill   BOOLEAN DEFAULT TRUE,
    gps_lat         DECIMAL(10,8),
    gps_lng         DECIMAL(11,8),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID,
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- SHED
CREATE TABLE shed (
    shed_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    shed_name           VARCHAR(100) NOT NULL,
    shed_number         INTEGER NOT NULL,
    capacity_birds      INTEGER NOT NULL,          -- hard ceiling — no overstocking allowed
    shed_type           VARCHAR(50),               -- conventional/cage/open-sided
    length_ft           DECIMAL,
    width_ft            DECIMAL,
    ventilation_type    VARCHAR(100),
    feeder_type         VARCHAR(100),
    drinker_type        VARCHAR(100),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE,
    UNIQUE (farm_id, shed_number)
);

-- BREED MASTER
CREATE TABLE breed (
    breed_id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    breed_name                  VARCHAR(100) NOT NULL UNIQUE,  -- BV-380, Lohmann Brown
    supplier                    VARCHAR(200),
    expected_lay_start_day      INTEGER NOT NULL DEFAULT 126,
    peak_hdp_percent            DECIMAL(5,2),
    peak_hdp_day                INTEGER,
    standard_hdp_curve          JSONB NOT NULL,  -- {day: expected_hdp_percent, ...}
    standard_mortality_rate     JSONB NOT NULL,  -- {stage: daily_rate_percent, ...}
    standard_feed_per_bird_g    JSONB NOT NULL,  -- {stage: grams_per_day, ...}
    expected_lay_period_weeks   INTEGER DEFAULT 72,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID,
    is_deleted                  BOOLEAN DEFAULT FALSE
);

-- USER
CREATE TABLE app_user (
    user_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cognito_sub         VARCHAR(200) UNIQUE,       -- Cognito user subject ID
    full_name           VARCHAR(200) NOT NULL,
    phone_number        VARCHAR(20),
    role                VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'supervisor')),
    assigned_farm_id    UUID REFERENCES farm(farm_id),  -- NULL for owner
    pin_hash            VARCHAR(200),              -- hashed 4-digit PIN for supervisors
    language_pref       VARCHAR(10) DEFAULT 'hi',  -- hi/bn/en
    expo_push_token     VARCHAR(200),              -- for push notifications
    is_active           BOOLEAN DEFAULT TRUE,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE,
    CONSTRAINT supervisor_has_farm CHECK (
        role = 'owner' OR assigned_farm_id IS NOT NULL
    )
);

-- VACCINE MASTER
CREATE TABLE vaccine_master (
    vaccine_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vaccine_name            VARCHAR(200) NOT NULL,
    disease_target          VARCHAR(200),
    vaccine_type            VARCHAR(50) NOT NULL,  -- live/killed/toxoid/recombinant
    conflict_group          VARCHAR(5) NOT NULL,   -- A/B/C — same group cannot overlap
    default_method          VARCHAR(50),           -- water/injection/eye_drop/spray/wing_web
    default_dose_ml_per_bird DECIMAL(8,4),
    min_gap_before_days     INTEGER DEFAULT 5,
    min_gap_after_days      INTEGER DEFAULT 5,
    storage_temp_min_c      DECIMAL(4,1),
    storage_temp_max_c      DECIMAL(4,1),
    cold_chain_required     BOOLEAN DEFAULT TRUE,
    notes_for_worker        TEXT,                  -- plain language instructions
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- VACCINE SCHEDULE TEMPLATE (one per breed)
CREATE TABLE vaccine_schedule_template (
    template_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name   VARCHAR(200) NOT NULL,
    breed_id        UUID NOT NULL REFERENCES breed(breed_id),
    version_number  INTEGER NOT NULL DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    superseded_by   UUID REFERENCES vaccine_schedule_template(template_id),
    change_reason   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID,
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- VACCINE SCHEDULE ITEMS (line items per template)
CREATE TABLE vaccine_schedule_item (
    item_id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id                 UUID NOT NULL REFERENCES vaccine_schedule_template(template_id),
    sequence_number             INTEGER NOT NULL,
    vaccine_id                  UUID NOT NULL REFERENCES vaccine_master(vaccine_id),
    target_day                  INTEGER NOT NULL,
    flexibility_window_days     INTEGER DEFAULT 3,
    method                      VARCHAR(50),
    dose_ml_per_bird            DECIMAL(8,4),
    is_mandatory                BOOLEAN DEFAULT TRUE,
    grace_days_before_escalate  INTEGER DEFAULT 1,
    post_vaccine_watch_days     INTEGER DEFAULT 7,
    worker_instructions         TEXT,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID,
    is_deleted                  BOOLEAN DEFAULT FALSE,
    UNIQUE (template_id, sequence_number)
);

-- FEED FORMULA
CREATE TABLE feed_formula (
    formula_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    formula_name    VARCHAR(200) NOT NULL,
    formula_code    VARCHAR(50) NOT NULL,
    flock_stage     VARCHAR(20) NOT NULL CHECK (flock_stage IN ('chick','grower','pre_layer','layer')),
    version_number  INTEGER NOT NULL DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    superseded_by   UUID REFERENCES feed_formula(formula_id),
    change_reason   TEXT,
    target_cp_pct   DECIMAL(5,2),
    target_energy   DECIMAL(8,2),  -- kcal/kg
    target_calcium  DECIMAL(5,2),
    target_phosphorus DECIMAL(5,2),
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID,
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- FEED FORMULA INGREDIENTS
CREATE TABLE feed_formula_ingredient (
    ingredient_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    formula_id          UUID NOT NULL REFERENCES feed_formula(formula_id),
    formula_version     INTEGER NOT NULL,          -- stamped at creation
    raw_material_id     UUID NOT NULL,             -- FK will be defined later
    quantity_per_100kg  DECIMAL(8,3) NOT NULL,
    is_critical         BOOLEAN DEFAULT FALSE,     -- if missing, block production
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- RAW MATERIAL MASTER
CREATE TABLE raw_material (
    material_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_name       VARCHAR(200) NOT NULL,
    unit                VARCHAR(20) DEFAULT 'kg',
    category            VARCHAR(50),               -- grain/protein/mineral/additive
    reorder_level_kg    DECIMAL(12,3),
    critical_days       INTEGER DEFAULT 7,         -- alert when stock < this many days
    primary_supplier    VARCHAR(200),
    secondary_supplier  VARCHAR(200),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- Add missing FK to feed_formula_ingredient
ALTER TABLE feed_formula_ingredient ADD CONSTRAINT fk_raw_material FOREIGN KEY (raw_material_id) REFERENCES raw_material(material_id);

-- ==========================================
-- OPERATIONAL TABLES
-- ==========================================

-- FLOCK
CREATE TABLE flock (
    flock_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_code              VARCHAR(30) NOT NULL UNIQUE,  -- F-F1-2025-047
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    breed_id                UUID NOT NULL REFERENCES breed(breed_id),
    vaccine_template_id     UUID REFERENCES vaccine_schedule_template(template_id),
    vaccine_template_version INTEGER,
    placement_date          DATE NOT NULL,
    initial_birds_placed    INTEGER NOT NULL,
    dead_on_arrival         INTEGER DEFAULT 0,
    net_birds_started       INTEGER NOT NULL,      -- initial_birds_placed - dead_on_arrival
    source_hatchery         VARCHAR(200),
    chick_batch_ref         VARCHAR(100),
    transport_hours         DECIMAL(4,1),
    arrival_condition       VARCHAR(50),           -- good/minor_losses/significant_losses
    flock_status            VARCHAR(20) DEFAULT 'active' CHECK (
                                flock_status IN ('active','depleted','sold','condemned')
                            ),
    depletion_date          DATE,
    depletion_reason        TEXT,
    depletion_approved_by   UUID REFERENCES app_user(user_id),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES app_user(user_id),
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- FEED BATCH (Produced at Mill)
CREATE TABLE feed_batch (
    batch_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code          VARCHAR(50) NOT NULL UNIQUE,   -- FM-F1-20250414-003
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    formula_id          UUID NOT NULL REFERENCES feed_formula(formula_id),
    formula_version     INTEGER NOT NULL,              -- stamped at production — immutable
    production_date     DATE NOT NULL,
    quantity_kg         DECIMAL(12,3) NOT NULL,
    quality_status      VARCHAR(20) DEFAULT 'pass' CHECK (
                            quality_status IN ('pass','fail','conditional')
                        ),
    quality_notes       TEXT,
    quality_checked_by  UUID REFERENCES app_user(user_id),
    storage_location    VARCHAR(200),
    remaining_qty_kg    DECIMAL(12,3),                 -- decremented on dispatch
    produced_by         UUID NOT NULL REFERENCES app_user(user_id),
    released_by         UUID REFERENCES app_user(user_id),  -- owner approval if conditional/fail
    release_note        TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- DAILY FLOCK SNAPSHOT (The Heartbeat)
CREATE TABLE daily_flock_snapshot (
    snapshot_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id                UUID NOT NULL REFERENCES flock(flock_id),
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    snapshot_date           DATE NOT NULL,
    bird_age_days           INTEGER NOT NULL,
    flock_stage             VARCHAR(20) NOT NULL,

    -- bird count
    opening_bird_count      INTEGER NOT NULL,
    mortality_count         INTEGER NOT NULL DEFAULT 0,
    culled_sick_count       INTEGER NOT NULL DEFAULT 0,
    other_movements_count   INTEGER NOT NULL DEFAULT 0,   -- auto from movements
    arrivals_count          INTEGER NOT NULL DEFAULT 0,   -- auto from movements
    closing_bird_count      INTEGER NOT NULL,             -- auto calculated

    -- feed
    feed_batch_id           UUID REFERENCES feed_batch(batch_id),
    formula_id              UUID,
    formula_version         INTEGER,
    feed_issued_kg          DECIMAL(10,3) DEFAULT 0,
    feed_returned_kg        DECIMAL(10,3) DEFAULT 0,
    feed_net_kg             DECIMAL(10,3),                -- auto
    feed_per_bird_g         DECIMAL(8,2),                 -- auto
    expected_feed_g         DECIMAL(8,2),                 -- auto from breed
    feed_variance_g         DECIMAL(8,2),                 -- auto

    -- eggs
    eggs_collected          INTEGER DEFAULT 0,
    eggs_broken             INTEGER DEFAULT 0,
    eggs_floor              INTEGER DEFAULT 0,
    eggs_saleable           INTEGER,                      -- auto
    hdp_percent             DECIMAL(6,3),                 -- auto
    hdp_expected            DECIMAL(6,3),                 -- auto from breed curve
    hdp_variance            DECIMAL(6,3),                 -- auto

    -- water and environment
    water_consumed_litres   DECIMAL(10,2),
    morning_temp_c          DECIMAL(4,1),
    evening_temp_c          DECIMAL(4,1),
    observations            TEXT,

    -- accountability
    reported_by_name        VARCHAR(200) NOT NULL,
    reported_by_login       UUID NOT NULL REFERENCES app_user(user_id),
    entry_timestamp         TIMESTAMPTZ DEFAULT NOW(),
    sync_status             VARCHAR(20) DEFAULT 'local',
    validated               BOOLEAN DEFAULT FALSE,
    validation_flags        JSONB DEFAULT '[]',

    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE,

    UNIQUE (flock_id, snapshot_date),
    CONSTRAINT eggs_check CHECK (eggs_broken + eggs_floor <= eggs_collected),
    CONSTRAINT feed_check  CHECK (feed_returned_kg <= feed_issued_kg),
    CONSTRAINT mortality_check CHECK (
        mortality_count >= 0 AND mortality_count <= opening_bird_count
    )
);

-- VACCINE EVENT
CREATE TABLE vaccine_event (
    event_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id                UUID NOT NULL REFERENCES flock(flock_id),
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    schedule_item_id        UUID REFERENCES vaccine_schedule_item(item_id),  -- null if adhoc
    is_adhoc                BOOLEAN DEFAULT FALSE,
    vaccine_id              UUID NOT NULL REFERENCES vaccine_master(vaccine_id),
    event_type              VARCHAR(30) NOT NULL,   -- scheduled/emergency/booster/catch_up

    -- planned
    target_date             DATE NOT NULL,
    earliest_acceptable     DATE,
    latest_acceptable       DATE,
    planned_method          VARCHAR(50),
    planned_dose_ml         DECIMAL(8,4),

    -- actual
    actual_date             DATE,
    actual_method           VARCHAR(50),
    batch_number            VARCHAR(100),
    manufacturer            VARCHAR(200),
    batch_expiry            DATE,
    dose_ml_actual          DECIMAL(8,4),
    birds_total             INTEGER,               -- auto from snapshot
    birds_covered           INTEGER,
    coverage_percent        DECIMAL(5,2),          -- auto
    administered_by         UUID REFERENCES app_user(user_id),
    delay_reason            VARCHAR(200),
    worker_observations     TEXT,

    -- approval
    required_approval       VARCHAR(20) DEFAULT 'owner',
    approved_by             UUID REFERENCES app_user(user_id),
    approval_timestamp      TIMESTAMPTZ,
    approval_note           TEXT,

    -- status
    status                  VARCHAR(30) NOT NULL DEFAULT 'scheduled' CHECK (
        status IN ('scheduled','upcoming','due_today','administered',
                   'overdue','critically_overdue','skipped','rescheduled')
    ),
    status_updated_at       TIMESTAMPTZ DEFAULT NOW(),

    -- rescheduling
    was_rescheduled         BOOLEAN DEFAULT FALSE,
    original_target_date    DATE,
    reschedule_reason       TEXT,
    reschedule_approved_by  UUID REFERENCES app_user(user_id),
    conflict_event_id       UUID REFERENCES vaccine_event(event_id),

    -- post-vaccine watch
    watch_period_days       INTEGER DEFAULT 7,
    watch_end_date          DATE,
    watch_status            VARCHAR(20) DEFAULT 'not_started',

    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- FEED BATCH INGREDIENTS
CREATE TABLE feed_batch_ingredient (
    entry_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id            UUID NOT NULL REFERENCES feed_batch(batch_id),
    raw_material_id     UUID NOT NULL REFERENCES raw_material(material_id),
    lot_number          VARCHAR(100),
    formula_qty_kg      DECIMAL(10,3) NOT NULL,
    actual_qty_kg       DECIMAL(10,3) NOT NULL,
    variance_kg         DECIMAL(10,3),             -- auto
    variance_pct        DECIMAL(6,2),              -- auto
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- FEED DISPATCH
CREATE TABLE feed_dispatch (
    dispatch_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    dispatch_date       DATE NOT NULL,
    dispatch_time       TIME,
    batch_id            UUID NOT NULL REFERENCES feed_batch(batch_id),
    to_shed_id          UUID NOT NULL REFERENCES shed(shed_id),
    to_flock_id         UUID NOT NULL REFERENCES flock(flock_id),
    qty_dispatched_kg   DECIMAL(10,3) NOT NULL,
    qty_received_kg     DECIMAL(10,3),             -- confirmed by shed supervisor
    variance_kg         DECIMAL(10,3),             -- auto
    dispatched_by       UUID NOT NULL REFERENCES app_user(user_id),
    received_by         UUID REFERENCES app_user(user_id),
    received_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- RAW MATERIAL STOCK
CREATE TABLE raw_material_stock (
    stock_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    material_id         UUID NOT NULL REFERENCES raw_material(material_id),
    current_stock_kg    DECIMAL(12,3) NOT NULL DEFAULT 0,
    last_updated        TIMESTAMPTZ DEFAULT NOW(),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted              BOOLEAN DEFAULT FALSE,
    UNIQUE (farm_id, material_id)
);

-- RAW MATERIAL MOVEMENT
CREATE TABLE raw_material_movement (
    movement_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    material_id         UUID NOT NULL REFERENCES raw_material(material_id),
    movement_date       DATE NOT NULL,
    movement_type       VARCHAR(30) NOT NULL CHECK (
                            movement_type IN ('purchase','mill_consumption',
                                              'adjustment','transfer')
                        ),
    quantity_kg         DECIMAL(12,3) NOT NULL,    -- positive=IN, negative=OUT
    reference_id        UUID,                      -- batch_id or purchase ref
    balance_after_kg    DECIMAL(12,3) NOT NULL,    -- auto
    entered_by          UUID NOT NULL REFERENCES app_user(user_id),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- VACCINE INVENTORY
CREATE TABLE vaccine_inventory (
    inv_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    vaccine_id          UUID NOT NULL REFERENCES vaccine_master(vaccine_id),
    batch_number        VARCHAR(100) NOT NULL,
    manufacturer        VARCHAR(200),
    vials_received      INTEGER NOT NULL,
    vials_remaining     INTEGER NOT NULL,
    dose_per_vial       INTEGER NOT NULL,
    doses_remaining     INTEGER NOT NULL,           -- auto: vials_remaining * dose_per_vial
    expiry_date         DATE NOT NULL,
    storage_location    VARCHAR(200),
    received_date       DATE NOT NULL,
    received_by         UUID NOT NULL REFERENCES app_user(user_id),
    cold_chain_ok       BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- HEALTH EVENT
CREATE TABLE health_event (
    event_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id                UUID NOT NULL REFERENCES flock(flock_id),
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    event_date              DATE NOT NULL,
    event_type              VARCHAR(50) NOT NULL,   -- disease_suspicion/injury/deficiency/stress/other
    description             TEXT NOT NULL,
    birds_affected_est      INTEGER,
    vet_consulted           BOOLEAN DEFAULT FALSE,
    vet_name                VARCHAR(200),
    vet_recommendation      TEXT,
    treatment_product       VARCHAR(200),
    treatment_duration_days INTEGER,
    outcome                 VARCHAR(30),            -- resolved/ongoing/escalated
    linked_vaccine_event_id UUID REFERENCES vaccine_event(event_id),
    reported_by_name        VARCHAR(200) NOT NULL,
    reported_by_login       UUID NOT NULL REFERENCES app_user(user_id),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- FLOCK BIRD MOVEMENT
CREATE TABLE flock_bird_movement (
    movement_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id            UUID NOT NULL REFERENCES flock(flock_id),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    shed_id             UUID NOT NULL REFERENCES shed(shed_id),
    movement_date       DATE NOT NULL,
    movement_type       VARCHAR(30) NOT NULL CHECK (
                            movement_type IN ('sold','transferred_out','condemned',
                                              'theft_suspected','missing_unknown',
                                              'transfer_in')
                        ),
    direction           VARCHAR(5) NOT NULL CHECK (direction IN ('out','in')),
    bird_count          INTEGER NOT NULL CHECK (bird_count > 0),
    reason_note         TEXT,
    bird_count_before   INTEGER NOT NULL,           -- auto at time of report
    bird_count_after    INTEGER,                    -- auto after approval
    destination_farm_id UUID REFERENCES farm(farm_id),   -- for transfers
    destination_shed_id UUID REFERENCES shed(shed_id),
    linked_movement_id  UUID REFERENCES flock_bird_movement(movement_id),
    reported_by_name    VARCHAR(200) NOT NULL,
    reported_by_login   UUID NOT NULL REFERENCES app_user(user_id),
    status              VARCHAR(20) DEFAULT 'pending' CHECK (
                            status IN ('pending','approved','rejected')
                        ),
    approved_by         UUID REFERENCES app_user(user_id),
    approval_timestamp  TIMESTAMPTZ,
    sync_status         VARCHAR(20) DEFAULT 'local',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- SYSTEM ALERT
CREATE TABLE system_alert (
    alert_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID REFERENCES farm(farm_id),   -- null = all farms
    flock_id            UUID REFERENCES flock(flock_id),
    alert_level         VARCHAR(20) NOT NULL CHECK (
                            alert_level IN ('info','warning','alert','critical')
                        ),
    alert_type          VARCHAR(100) NOT NULL,
    title               VARCHAR(300) NOT NULL,
    body                TEXT NOT NULL,
    action_required     BOOLEAN DEFAULT FALSE,
    action_taken        TEXT,
    target_role         VARCHAR(20) DEFAULT 'owner',
    target_user_id      UUID REFERENCES app_user(user_id),
    push_sent           BOOLEAN DEFAULT FALSE,
    push_sent_at        TIMESTAMPTZ,
    read_at             TIMESTAMPTZ,
    acknowledged_at     TIMESTAMPTZ,
    acknowledged_by     UUID REFERENCES app_user(user_id),
    auto_resolved_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- INTELLIGENCE FLAG
CREATE TABLE intelligence_flag (
    flag_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID REFERENCES farm(farm_id),
    flock_id            UUID REFERENCES flock(flock_id),
    snapshot_id         UUID REFERENCES daily_flock_snapshot(snapshot_id),
    flag_type           VARCHAR(100) NOT NULL,      -- production_drop/mortality_trend/etc
    severity            VARCHAR(20) NOT NULL,
    triggered_at        DATE NOT NULL,
    investigation       JSONB NOT NULL DEFAULT '{}',  -- structured report
    related_events      JSONB DEFAULT '[]',
    pattern_data        JSONB DEFAULT '{}',
    alert_created       BOOLEAN DEFAULT FALSE,
    alert_id            UUID REFERENCES system_alert(alert_id),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);
