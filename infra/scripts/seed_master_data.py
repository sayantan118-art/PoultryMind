#!/usr/bin/env python3
"""
Poultry Farm Command Center — Master Data Seeder v4.0
Generates SQL INSERT statements for master data bootstrap.

Usage:
    python seed_master_data.py > seed.sql
    psql poultry_dev < seed.sql
"""

import uuid
import json
from datetime import datetime, timedelta
from typing import List, Tuple

def generate_seed_sql() -> str:
    """Generate SQL INSERT statements for all master data."""
    
    company_id = "00000000-0000-0000-0000-000000000001"
    sql: List[str] = []

    # ==========================================
    # 1. COMPANY (Single row)
    # ==========================================
    sql.append(f"""
-- COMPANY
INSERT INTO company (company_id, name, owner_name, owner_phone, created_at, updated_at, is_deleted)
VALUES (
    '{company_id}',
    'Enterprise Poultry Farms Pvt Ltd',
    'Rajesh Kumar',
    '+91-9876543210',
    NOW(),
    NOW(),
    FALSE
) ON CONFLICT (company_id) DO NOTHING;
""")

    # ==========================================
    # 2. FARMS (4 farms across districts)
    # ==========================================
    farms = [
        ("Farm 1 — North", "F1", "District A", "23.1815", "79.9864"),
        ("Farm 2 — East", "F2", "District A", "23.2156", "79.8711"),
        ("Farm 3 — South", "F3", "District B", "23.0225", "79.5555"),
        ("Farm 4 — West", "F4", "District C", "23.5505", "78.5721"),
    ]

    farm_ids = {}
    sql.append("-- FARMS")
    for name, code, dist, lat, lng in farms:
        f_id = str(uuid.uuid4())
        farm_ids[code] = f_id
        sql.append(f"""
INSERT INTO farm (farm_id, company_id, farm_name, farm_code, district, state, has_feed_mill, gps_lat, gps_lng, is_active, created_at, updated_at, is_deleted)
VALUES (
    '{f_id}',
    '{company_id}',
    '{name}',
    '{code}',
    '{dist}',
    'Telangana',
    TRUE,
    {lat},
    {lng},
    TRUE,
    NOW(),
    NOW(),
    FALSE
);""")

    # ==========================================
    # 3. BREEDS (Commonly used layer breeds)
    # ==========================================
    breeds = [
        ("BV-380", "Venkateshwara Hatcheries", 126, 95.5, 250),
        ("Lohmann Brown", "Lohmann Tierzucht", 120, 94.0, 245),
        ("Hy-Line Brown", "Hy-Line International", 118, 93.5, 240),
        ("Shaver Brown", "Shaver Genetics", 124, 94.8, 248),
    ]

    # HDP Curve: 0-140 days = 0%, 140-300 days = peak (90%), 300+ days = decline (75%)
    hdp_curve = {str(day): (0 if day < 140 else 90 if day < 300 else 75) for day in range(126, 501)}
    mortality_rate = {"brooding": 0.05, "grower": 0.02, "pre_layer": 0.015, "layer": 0.008}
    feed_rate = {"chick": 35, "grower": 75, "pre_layer": 100, "layer": 120}

    breed_ids = {}
    sql.append("\n-- BREEDS")
    for name, supplier, lay_start, peak_hdp, peak_day in breeds:
        b_id = str(uuid.uuid4())
        breed_ids[name] = b_id
        sql.append(f"""
INSERT INTO breed (breed_id, breed_name, supplier, expected_lay_start_day, peak_hdp_percent, peak_hdp_day, standard_hdp_curve, standard_mortality_rate, standard_feed_per_bird_g, expected_lay_period_weeks, created_at, updated_at, is_deleted)
VALUES (
    '{b_id}',
    '{name}',
    '{supplier}',
    {lay_start},
    {peak_hdp},
    {peak_day},
    '{json.dumps(hdp_curve)}'::jsonb,
    '{json.dumps(mortality_rate)}'::jsonb,
    '{json.dumps(feed_rate)}'::jsonb,
    72,
    NOW(),
    NOW(),
    FALSE
);""")

    # ==========================================
    # 4. VACCINES (Industry standard vaccines)
    # ==========================================
    vaccines = [
        ("Ranikhet — Lasota", "Newcastle Disease (RD)", "live", "A", "Water", 1, 5, 5, -70, -40),
        ("Gumboro — IBD", "Infectious Bursal Disease", "live", "A", "Water", 1, 5, 5, -70, -40),
        ("Fowl Pox — Live", "Fowl Pox", "live", "B", "Wing Web", 0, 7, 7, -70, -40),
        ("Mareks — Killed", "Mareks Disease", "killed", "C", "Injection", 0, 0, 0, 2, 8),
        ("Infectious Laryngotracheitis (ILT)", "ILT", "live", "D", "Instillation", 1, 5, 5, -70, -40),
        ("Infectious Coryza", "Infectious Coryza", "killed", "E", "Injection", 0, 0, 0, 2, 8),
        ("Salmonella (S-120)", "Salmonella Typhimurium", "live", "F", "Water/Spray", 1, 5, 5, -70, -40),
    ]

    sql.append("\n-- VACCINES")
    vaccine_ids = {}
    for name, disease, vtype, group, method, _, before, after, temp_min, temp_max in vaccines:
        v_id = str(uuid.uuid4())
        vaccine_ids[name] = v_id
        sql.append(f"""
INSERT INTO vaccine_master (vaccine_id, vaccine_name, disease_target, vaccine_type, conflict_group, default_method, min_gap_before_days, min_gap_after_days, storage_temp_min_c, storage_temp_max_c, cold_chain_required, is_active, created_at, updated_at, is_deleted)
VALUES (
    '{v_id}',
    '{name}',
    '{disease}',
    '{vtype}',
    '{group}',
    '{method}',
    {before},
    {after},
    {temp_min},
    {temp_max},
    TRUE,
    TRUE,
    NOW(),
    NOW(),
    FALSE
);""")

    # ==========================================
    # 5. RAW MATERIALS (Feed ingredients)
    # ==========================================
    materials = [
        ("Maize", "kg", "grain"),
        ("Soya Meal", "kg", "protein"),
        ("Rice Bran", "kg", "grain"),
        ("DORB (De-Oiled Rice Bran)", "kg", "grain"),
        ("Sunflower Meal", "kg", "protein"),
        ("Cotton Seed Meal", "kg", "protein"),
        ("Lime Stone", "kg", "mineral"),
        ("Di-Calcium Phosphate (DCP)", "kg", "mineral"),
        ("Rock Phosphate", "kg", "mineral"),
        ("Common Salt (NaCl)", "kg", "mineral"),
        ("DL-Methionine", "kg", "additive"),
        ("L-Lysine HCl", "kg", "additive"),
        ("Vitamin Premix", "kg", "additive"),
        ("Mineral Premix", "kg", "additive"),
        ("Enzyme Complex", "kg", "additive"),
        ("Probiotic Blend", "kg", "additive"),
    ]

    sql.append("\n-- RAW MATERIALS")
    material_ids = {}
    for mat_name, unit, category in materials:
        m_id = str(uuid.uuid4())
        material_ids[mat_name] = m_id
        sql.append(f"""
INSERT INTO raw_material (material_id, material_name, unit, category, reorder_level_kg, critical_days, created_at, updated_at, is_deleted)
VALUES (
    '{m_id}',
    '{mat_name}',
    '{unit}',
    '{category}',
    1000,
    7,
    NOW(),
    NOW(),
    FALSE
);""")

    # ==========================================
    # 6. FEED FORMULAS (By stage)
    # ==========================================
    formulas = [
        ("Starter — Chick (0-6 weeks)", "START-001", "chick", 22.0, 2900, 3.8, 0.8),
        ("Grower (6-12 weeks)", "GROW-001", "grower", 16.5, 2750, 3.0, 0.65),
        ("Developer — Pre-Layer (12-18 weeks)", "DEV-001", "pre_layer", 14.5, 2650, 3.5, 0.65),
        ("Layer — Production (18+ weeks)", "LAY-001", "layer", 16.5, 2850, 3.8, 0.8),
    ]

    sql.append("\n-- FEED FORMULAS")
    formula_ids = {}
    for f_name, f_code, stage, cp, energy, calcium, phos in formulas:
        fm_id = str(uuid.uuid4())
        formula_ids[stage] = fm_id
        sql.append(f"""
INSERT INTO feed_formula (formula_id, formula_name, formula_code, flock_stage, version_number, is_active, target_cp_pct, target_energy, target_calcium, target_phosphorus, created_at, updated_at, is_deleted)
VALUES (
    '{fm_id}',
    '{f_name}',
    '{f_code}',
    '{stage}',
    1,
    TRUE,
    {cp},
    {energy},
    {calcium},
    {phos},
    NOW(),
    NOW(),
    FALSE
);""")

    # ==========================================
    # 7. VACCINE SCHEDULE TEMPLATES (Per breed)
    # ==========================================
    bv380_schedule = [
        (1, "Ranikhet — Lasota", 5, "Water", 1),
        (2, "Gumboro — IBD", 10, "Water", 1),
        (3, "Fowl Pox — Live", 21, "Wing Web", 1),
        (4, "Mareks — Killed", 1, "Injection", 0),
        (5, "Infectious Laryngotracheitis (ILT)", 35, "Instillation", 1),
    ]

    sql.append("\n-- VACCINE SCHEDULE TEMPLATES")
    template_ids = {}
    for breed_name, breed_uuid in list(breed_ids.items())[:2]:  # Use first 2 breeds
        t_id = str(uuid.uuid4())
        template_ids[breed_name] = t_id
        sql.append(f"""
INSERT INTO vaccine_schedule_template (template_id, template_name, breed_id, version_number, is_active, created_at, updated_at, is_deleted)
VALUES (
    '{t_id}',
    '{breed_name} — Standard Schedule v1',
    '{breed_uuid}',
    1,
    TRUE,
    NOW(),
    NOW(),
    FALSE
);""")

        # Add schedule items
        sql.append(f"\n-- Vaccine items for {breed_name}")
        for seq, vac_name, target_day, method, mandatory in bv380_schedule:
            vac_uuid = vaccine_ids.get(vac_name)
            if vac_uuid:
                item_id = str(uuid.uuid4())
                sql.append(f"""
INSERT INTO vaccine_schedule_item (item_id, template_id, sequence_number, vaccine_id, target_day, flexibility_window_days, method, is_mandatory, grace_days_before_escalate, post_vaccine_watch_days, created_at, updated_at, is_deleted)
VALUES (
    '{item_id}',
    '{t_id}',
    {seq},
    '{vac_uuid}',
    {target_day},
    3,
    '{method}',
    {str(mandatory).lower()},
    1,
    7,
    NOW(),
    NOW(),
    FALSE
);""")

    return "\n".join(sql)


def main():
    """Generate and print SQL seed script."""
    print("-- ==========================================")
    print("-- Poultry Farm Command Center")
    print("-- Master Data Seed Script v4.0")
    print("-- Generated: " + datetime.now().isoformat())
    print("-- ==========================================\n")
    
    sql = generate_seed_sql()
    print(sql)
    
    print("\n-- ==========================================")
    print("-- Seed data generation complete")
    print("-- Usage: psql poultry_dev < seed.sql")
    print("-- ==========================================")


if __name__ == "__main__":
    main()
