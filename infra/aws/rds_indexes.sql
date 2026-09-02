-- Poultry Farm Command Center — Index Definitions v4.0
-- Location: infra/aws/rds_indexes.sql

-- ==========================================
-- FARM ISOLATION INDEXES (Critical for RLS & Query Speed)
-- ==========================================
CREATE INDEX idx_app_user_farm           ON app_user(assigned_farm_id);
CREATE INDEX idx_flock_farm              ON flock(farm_id);
CREATE INDEX idx_snapshot_farm           ON daily_flock_snapshot(farm_id);
CREATE INDEX idx_vaccine_event_farm      ON vaccine_event(farm_id);
CREATE INDEX idx_feed_batch_farm         ON feed_batch(farm_id);
CREATE INDEX idx_feed_dispatch_farm      ON feed_dispatch(farm_id);
CREATE INDEX idx_bird_movement_farm      ON flock_bird_movement(farm_id);
CREATE INDEX idx_health_event_farm       ON health_event(farm_id);
CREATE INDEX idx_system_alert_farm       ON system_alert(farm_id);
CREATE INDEX idx_raw_material_stock_farm ON raw_material_stock(farm_id);
CREATE INDEX idx_raw_material_mov_farm   ON raw_material_movement(farm_id);
CREATE INDEX idx_vaccine_inventory_farm  ON vaccine_inventory(farm_id);

-- ==========================================
-- OPERATIONAL LOOKUP INDEXES
-- ==========================================

-- Daily Snapshot Lookups
CREATE INDEX idx_snapshot_date             ON daily_flock_snapshot(snapshot_date);
CREATE INDEX idx_snapshot_flock            ON daily_flock_snapshot(flock_id);
-- Composite for direct day-level flock queries
CREATE INDEX idx_snapshot_flock_date       ON daily_flock_snapshot(flock_id, snapshot_date);

-- Flock Lookups
CREATE INDEX idx_flock_status              ON flock(flock_status);
CREATE INDEX idx_flock_shed                ON flock(shed_id);
CREATE INDEX idx_flock_breed               ON flock(breed_id);

-- Vaccine Lookups
CREATE INDEX idx_vaccine_event_status      ON vaccine_event(status);
CREATE INDEX idx_vaccine_event_target_date ON vaccine_event(target_date);
CREATE INDEX idx_vaccine_event_flock       ON vaccine_event(flock_id);

-- Feed Lookups
CREATE INDEX idx_feed_batch_date           ON feed_batch(production_date);
CREATE INDEX idx_feed_dispatch_date        ON feed_dispatch(dispatch_date);
CREATE INDEX idx_feed_dispatch_to_flock    ON feed_dispatch(to_flock_id);

-- Alert Lookups
CREATE INDEX idx_alert_level               ON system_alert(alert_level);
CREATE INDEX idx_alert_role                ON system_alert(target_role);
CREATE INDEX idx_alert_unread              ON system_alert(read_at) WHERE read_at IS NULL;
CREATE INDEX idx_alert_unacknowledged      ON system_alert(acknowledged_at) WHERE acknowledged_at IS NULL;

-- Bird Movement Lookups
CREATE INDEX idx_bird_movement_status      ON flock_bird_movement(status);
CREATE INDEX idx_bird_movement_flock_date  ON flock_bird_movement(flock_id, movement_date);

-- Inventory Lookups
CREATE INDEX idx_raw_material_mov_date     ON raw_material_movement(material_id, movement_date);
CREATE INDEX idx_vaccine_inv_expiry        ON vaccine_inventory(expiry_date);
CREATE INDEX idx_vaccine_inv_vaccine       ON vaccine_inventory(vaccine_id);
