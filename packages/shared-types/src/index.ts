/**
 * Shared TypeScript Types for Poultry Farm Command Center
 * Used by both Dashboard (React) and Supervisor App (React Native)
 */

// ==========================================
// AUTH & USER TYPES
// ==========================================

export type UserRole = 'owner' | 'supervisor';

export interface User {
  user_id: string;
  full_name: string;
  phone_number?: string;
  role: UserRole;
  assigned_farm_id?: string;
  language_pref: 'hi' | 'bn' | 'en';
  is_active: boolean;
  last_login_at?: string;
  created_at: string;
  updated_at: string;
}

export interface AuthToken {
  access_token: string;
  token_type: 'bearer';
  expires_in: number;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  user: User;
}

// ==========================================
// MASTER DATA TYPES
// ==========================================

export interface Company {
  company_id: string;
  name: string;
  owner_name: string;
  owner_phone?: string;
  created_at: string;
  updated_at: string;
}

export interface Farm {
  farm_id: string;
  company_id: string;
  farm_name: string;
  farm_code: string;
  district: string;
  state: string;
  has_feed_mill: boolean;
  gps_lat?: number;
  gps_lng?: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Shed {
  shed_id: string;
  farm_id: string;
  shed_name: string;
  shed_number: number;
  capacity_birds: number;
  shed_type?: string;
  length_ft?: number;
  width_ft?: number;
  ventilation_type?: string;
  feeder_type?: string;
  drinker_type?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Breed {
  breed_id: string;
  breed_name: string;
  supplier?: string;
  expected_lay_start_day: number;
  peak_hdp_percent?: number;
  peak_hdp_day?: number;
  standard_hdp_curve: Record<string, number>;
  standard_mortality_rate: Record<string, number>;
  standard_feed_per_bird_g: Record<string, number>;
  expected_lay_period_weeks: number;
  created_at: string;
  updated_at: string;
}

export interface VaccineMaster {
  vaccine_id: string;
  vaccine_name: string;
  disease_target: string;
  vaccine_type: 'live' | 'killed' | 'toxoid' | 'recombinant';
  conflict_group: string;
  default_method?: string;
  default_dose_ml_per_bird?: number;
  min_gap_before_days: number;
  min_gap_after_days: number;
  storage_temp_min_c?: number;
  storage_temp_max_c?: number;
  cold_chain_required: boolean;
  notes_for_worker?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface RawMaterial {
  material_id: string;
  material_name: string;
  unit: string;
  category: string;
  reorder_level_kg?: number;
  critical_days: number;
  primary_supplier?: string;
  secondary_supplier?: string;
  created_at: string;
  updated_at: string;
}

// ==========================================
// FLOCK TYPES
// ==========================================

export type FlockStatus = 'active' | 'depleted' | 'sold' | 'condemned';
export type FlockStage = 'chick' | 'grower' | 'pre_layer' | 'layer';

export interface Flock {
  flock_id: string;
  flock_code: string;
  farm_id: string;
  shed_id: string;
  breed_id: string;
  vaccine_template_id?: string;
  placement_date: string;
  initial_birds_placed: number;
  dead_on_arrival: number;
  net_birds_started: number;
  source_hatchery?: string;
  chick_batch_ref?: string;
  flock_status: FlockStatus;
  created_at: string;
  updated_at: string;
}

export interface DailyFlockSnapshot {
  snapshot_id: string;
  flock_id: string;
  farm_id: string;
  shed_id: string;
  snapshot_date: string;
  bird_age_days: number;
  flock_stage: FlockStage;
  opening_bird_count: number;
  mortality_count: number;
  culled_sick_count: number;
  other_movements_count: number;
  arrivals_count: number;
  closing_bird_count: number;
  eggs_collected: number;
  eggs_broken: number;
  eggs_floor: number;
  eggs_saleable: number;
  hdp_percent: string;
  reported_by_name: string;
  reported_by_login: string;
  validation_flags: ValidationFlag[];
  created_at: string;
  updated_at: string;
}

export interface ValidationFlag {
  flag_type: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
}

// ==========================================
// VACCINE TYPES
// ==========================================

export type VaccineStatus =
  | 'scheduled'
  | 'upcoming'
  | 'due_today'
  | 'administered'
  | 'overdue'
  | 'critically_overdue'
  | 'skipped'
  | 'rescheduled';

export interface VaccineScheduleTemplate {
  template_id: string;
  template_name: string;
  breed_id: string;
  version_number: number;
  is_active: boolean;
  superseded_by?: string;
  change_reason?: string;
  created_at: string;
  updated_at: string;
}

export interface VaccineScheduleItem {
  item_id: string;
  template_id: string;
  sequence_number: number;
  vaccine_id: string;
  target_day: number;
  flexibility_window_days: number;
  method?: string;
  dose_ml_per_bird?: number;
  is_mandatory: boolean;
  grace_days_before_escalate: number;
  post_vaccine_watch_days: number;
  worker_instructions?: string;
  created_at: string;
  updated_at: string;
}

export interface VaccineEvent {
  event_id: string;
  flock_id: string;
  farm_id: string;
  shed_id: string;
  schedule_item_id?: string;
  is_adhoc: boolean;
  vaccine_id: string;
  target_date: string;
  earliest_acceptable?: string;
  latest_acceptable?: string;
  actual_date?: string;
  actual_method?: string;
  batch_number?: string;
  coverage_percent?: number;
  status: VaccineStatus;
  created_at: string;
  updated_at: string;
}

// ==========================================
// FEED TYPES
// ==========================================

export type FeedStage = 'chick' | 'grower' | 'pre_layer' | 'layer';

export interface FeedFormula {
  formula_id: string;
  formula_name: string;
  formula_code: string;
  flock_stage: FeedStage;
  version_number: number;
  is_active: boolean;
  superseded_by?: string;
  target_cp_pct?: number;
  target_energy?: number;
  target_calcium?: number;
  target_phosphorus?: number;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface FeedFormulaIngredient {
  ingredient_id: string;
  formula_id: string;
  formula_version: number;
  raw_material_id: string;
  quantity_per_100kg: number;
  is_critical: boolean;
  created_at: string;
  updated_at: string;
}

export interface FeedBatch {
  batch_id: string;
  batch_code: string;
  farm_id: string;
  formula_id: string;
  formula_version: number;
  production_date: string;
  quantity_kg: number;
  quality_status: 'pass' | 'fail' | 'pending';
  remaining_qty_kg: number;
  created_at: string;
  updated_at: string;
}

export interface FeedDispatch {
  dispatch_id: string;
  farm_id: string;
  dispatch_date: string;
  batch_id: string;
  to_shed_id: string;
  to_flock_id: string;
  qty_dispatched_kg: number;
  qty_received_kg?: number;
  created_at: string;
  updated_at: string;
}

// ==========================================
// HEALTH & MOVEMENT TYPES
// ==========================================

export interface HealthEvent {
  event_id: string;
  flock_id: string;
  farm_id: string;
  shed_id: string;
  event_date: string;
  event_type: string;
  description: string;
  reported_by_name: string;
  reported_by_login: string;
  created_at: string;
  updated_at: string;
}

export type MovementType =
  | 'sold'
  | 'transferred_out'
  | 'condemned'
  | 'theft_suspected'
  | 'missing_unknown'
  | 'transfer_in';

export type MovementStatus = 'pending' | 'approved' | 'rejected';

export interface BirdMovement {
  movement_id: string;
  flock_id: string;
  farm_id: string;
  shed_id: string;
  movement_date: string;
  movement_type: MovementType;
  bird_count: number;
  status: MovementStatus;
  reported_by_name: string;
  reported_by_login: string;
  created_at: string;
  updated_at: string;
}

// ==========================================
// INVENTORY TYPES
// ==========================================

export interface RawMaterialStock {
  stock_id: string;
  farm_id: string;
  material_id: string;
  current_stock_kg: number;
  created_at: string;
  updated_at: string;
}

export interface VaccineInventory {
  inventory_id: string;
  farm_id: string;
  vaccine_id: string;
  batch_number: string;
  vials_remaining: number;
  doses_remaining: number;
  expiry_date: string;
  created_at: string;
  updated_at: string;
}

// ==========================================
// ALERT TYPES
// ==========================================

export type AlertLevel = 'info' | 'warning' | 'critical';

export interface SystemAlert {
  alert_id: string;
  farm_id?: string;
  flock_id?: string;
  alert_level: AlertLevel;
  alert_type: string;
  title: string;
  body: string;
  action_required: boolean;
  target_role: UserRole;
  read_at?: string;
  acknowledged_at?: string;
  created_at: string;
  updated_at: string;
}

export interface IntelligenceFlag {
  flag_id: string;
  farm_id?: string;
  flock_id?: string;
  snapshot_id?: string;
  flag_type: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  triggered_at: string;
  investigation: Record<string, any>;
  created_at: string;
  updated_at: string;
}

// ==========================================
// API RESPONSE TYPES
// ==========================================

export interface ApiResponse<T> {
  status: number;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    per_page: number;
    total: number;
    total_pages: number;
  };
}

// ==========================================
// DASHBOARD TYPES
// ==========================================

export interface FarmDashboardSummary {
  farm_id: string;
  farm_name: string;
  total_birds: number;
  active_flocks: number;
  total_mortality_today: number;
  avg_hdp_today: string;
  avg_feed_consumption_today: number;
  critical_alerts: number;
  vaccines_due: number;
  movements_pending: number;
}

export interface OwnerDashboardSummary {
  farms: FarmDashboardSummary[];
  total_production_today: number;
  total_mortality_today: number;
  total_birds_active: number;
  critical_alerts: number;
  pending_approvals: number;
}

// ==========================================
// SYNC TYPES (FOR MOBILE OFFLINE)
// ==========================================

export interface SyncQueueItem {
  id: string;
  table_name: string;
  operation: 'insert' | 'update' | 'delete';
  data: Record<string, any>;
  created_at: string;
  synced: boolean;
}

export interface SyncConflict {
  item_id: string;
  local_version: Record<string, any>;
  server_version: Record<string, any>;
  resolved: boolean;
  resolution: 'local' | 'server';
}
