# apps/api/models/master.py
import uuid
from sqlalchemy import Column, String, Integer, Boolean, Numeric, ForeignKey, UniqueConstraint, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from .base import Base, AuditMixin

class Company(Base, AuditMixin):
    __tablename__ = "company"
    company_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(200), nullable=False)
    owner_name = Column(String(200), nullable=False)
    owner_phone = Column(String(20))
    
    farms = relationship("Farm", back_populates="company")

class Farm(Base, AuditMixin):
    __tablename__ = "farm"
    farm_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id = Column(UUID(as_uuid=True), ForeignKey("company.company_id"), nullable=False)
    farm_name = Column(String(200), nullable=False)
    farm_code = Column(String(10), nullable=False, unique=True)
    district = Column(String(100))
    state = Column(String(100))
    has_feed_mill = Column(Boolean, default=True)
    gps_lat = Column(Numeric(10, 8))
    gps_lng = Column(Numeric(11, 8))
    is_active = Column(Boolean, default=True)

    company = relationship("Company", back_populates="farms")
    sheds = relationship("Shed", back_populates="farm")

class Shed(Base, AuditMixin):
    __tablename__ = "shed"
    shed_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    shed_name = Column(String(100), nullable=False)
    shed_number = Column(Integer, nullable=False)
    capacity_birds = Column(Integer, nullable=False)
    shed_type = Column(String(50))
    length_ft = Column(Numeric)
    width_ft = Column(Numeric)
    ventilation_type = Column(String(100))
    feeder_type = Column(String(100))
    drinker_type = Column(String(100))
    is_active = Column(Boolean, default=True)

    __table_args__ = (UniqueConstraint("farm_id", "shed_number", name="uq_farm_shed"),)
    farm = relationship("Farm", back_populates="sheds")

class Breed(Base, AuditMixin):
    __tablename__ = "breed"
    breed_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    breed_name = Column(String(100), nullable=False, unique=True)
    supplier = Column(String(200))
    expected_lay_start_day = Column(Integer, nullable=False, default=126)
    peak_hdp_percent = Column(Numeric(5, 2))
    peak_hdp_day = Column(Integer)
    standard_hdp_curve = Column(JSONB, nullable=False)
    standard_mortality_rate = Column(JSONB, nullable=False)
    standard_feed_per_bird_g = Column(JSONB, nullable=False)
    expected_lay_period_weeks = Column(Integer, default=72)

class AppUser(Base, AuditMixin):
    __tablename__ = "app_user"
    user_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    cognito_sub = Column(String(200), unique=True)
    full_name = Column(String(200), nullable=False)
    phone_number = Column(String(20))
    role = Column(String(20), nullable=False)
    assigned_farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=True)
    pin_hash = Column(String(200))
    language_pref = Column(String(10), default="hi")
    expo_push_token = Column(String(200))
    is_active = Column(Boolean, default=True)
    
    __table_args__ = (
        CheckConstraint("role IN ('owner', 'supervisor')", name="check_user_role"),
    )

class VaccineMaster(Base, AuditMixin):
    __tablename__ = "vaccine_master"
    vaccine_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vaccine_name = Column(String(200), nullable=False)
    disease_target = Column(String(200))
    vaccine_type = Column(String(50), nullable=False)
    conflict_group = Column(String(5), nullable=False)
    default_method = Column(String(50))
    default_dose_ml_per_bird = Column(Numeric(8, 4))
    min_gap_before_days = Column(Integer, default=5)
    min_gap_after_days = Column(Integer, default=5)
    storage_temp_min_c = Column(Numeric(4, 1))
    storage_temp_max_c = Column(Numeric(4, 1))
    cold_chain_required = Column(Boolean, default=True)
    notes_for_worker = Column(String)
    is_active = Column(Boolean, default=True)

class RawMaterial(Base, AuditMixin):
    __tablename__ = "raw_material"
    material_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    material_name = Column(String(200), nullable=False)
    unit = Column(String(20), default="kg")
    category = Column(String(50))
    reorder_level_kg = Column(Numeric(12, 3))
    critical_days = Column(Integer, default=7)
    primary_supplier = Column(String(200))
    secondary_supplier = Column(String(200))
