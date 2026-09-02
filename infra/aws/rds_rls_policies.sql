-- Poultry Farm Command Center — RLS Policies v4.0
-- Location: infra/aws/rds_rls_policies.sql

-- ==========================================
-- RLS CONFIGURATION
-- ==========================================

-- Helper function: get current user's role from session variable
-- In production, the API will set this after verifying the JWT
CREATE OR REPLACE FUNCTION current_user_role() RETURNS TEXT AS $$
  SELECT current_setting('app.user_role', true);
$$ LANGUAGE sql STABLE;

-- Helper function: get current user's farm_id from session variable
CREATE OR REPLACE FUNCTION current_user_farm_id() RETURNS UUID AS $$
  BEGIN
    RETURN current_setting('app.farm_id', true)::UUID;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql STABLE;

-- Enable RLS on all operational tables
ALTER TABLE farm                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE shed                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE flock                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_flock_snapshot  ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccine_event         ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_batch            ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_dispatch         ENABLE ROW LEVEL SECURITY;
ALTER TABLE flock_bird_movement   ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_event          ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_alert          ENABLE ROW LEVEL SECURITY;
ALTER TABLE raw_material_stock    ENABLE ROW LEVEL SECURITY;
ALTER TABLE raw_material_movement ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccine_inventory     ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_user              ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICIES: OWNER (See All)
-- ==========================================

-- Generic owner policy for all tables
-- We define specific policies for each table to be explicit

-- FARM
CREATE POLICY owner_all_farm ON farm FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_read_own_farm ON farm FOR SELECT TO authenticated USING (farm_id = current_user_farm_id());

-- SHED
CREATE POLICY owner_all_shed ON shed FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_read_own_shed ON shed FOR SELECT TO authenticated USING (farm_id = current_user_farm_id());

-- FLOCK
CREATE POLICY owner_all_flock ON flock FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_read_own_flock ON flock FOR SELECT TO authenticated USING (farm_id = current_user_farm_id());

-- DAILY SNAPSHOT
CREATE POLICY owner_all_snapshot ON daily_flock_snapshot FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_snapshot ON daily_flock_snapshot FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- VACCINE EVENT
CREATE POLICY owner_all_vaccine ON vaccine_event FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_vaccine ON vaccine_event FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- FEED BATCH
CREATE POLICY owner_all_feed_batch ON feed_batch FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_feed_batch ON feed_batch FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- FEED DISPATCH
CREATE POLICY owner_all_feed_dispatch ON feed_dispatch FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_feed_dispatch ON feed_dispatch FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- BIRD MOVEMENT
CREATE POLICY owner_all_bird_movement ON flock_bird_movement FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_bird_movement ON flock_bird_movement FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- HEALTH EVENT
CREATE POLICY owner_all_health ON health_event FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_health ON health_event FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- SYSTEM ALERT
CREATE POLICY owner_all_alert ON system_alert FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_alert ON system_alert FOR SELECT TO authenticated USING (farm_id = current_user_farm_id() OR farm_id IS NULL);
CREATE POLICY supervisor_update_own_alert ON system_alert FOR UPDATE TO authenticated USING (farm_id = current_user_farm_id());

-- STOCK & INVENTORY
CREATE POLICY owner_all_raw_stock ON raw_material_stock FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_raw_stock ON raw_material_stock FOR SELECT TO authenticated USING (farm_id = current_user_farm_id());

CREATE POLICY owner_all_raw_mov ON raw_material_movement FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_raw_mov ON raw_material_movement FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

CREATE POLICY owner_all_vac_inv ON vaccine_inventory FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY supervisor_farm_vac_inv ON vaccine_inventory FOR ALL TO authenticated 
    USING (farm_id = current_user_farm_id())
    WITH CHECK (farm_id = current_user_farm_id());

-- USER TABLE (Privacy)
CREATE POLICY owner_all_users ON app_user FOR ALL TO authenticated USING (current_user_role() = 'owner');
CREATE POLICY users_read_own ON app_user FOR SELECT TO authenticated USING (user_id = (current_setting('app.user_id', true)::UUID));
