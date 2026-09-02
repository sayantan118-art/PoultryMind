# apps/api/models/flock.py
import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, Date, CheckConstraint, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from .base import Base, AuditMixin

class Flock(Base, AuditMixin):
    __tablename__ = "flock"
    flock_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flock_code = Column(String(30), nullable=False, unique=True)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.shed_id"), nullable=False)
    breed_id = Column(UUID(as_uuid=True), ForeignKey("breed.breed_id"), nullable=False)
    vaccine_template_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_template.template_id"), nullable=True)
    vaccine_template_version = Column(Integer)
    placement_date = Column(Date, nullable=False)
    initial_birds_placed = Column(Integer, nullable=False)
    dead_on_arrival = Column(Integer, default=0)
    net_birds_started = Column(Integer, nullable=False)
    source_hatchery = Column(String(200))
    chick_batch_ref = Column(String(100))
    flock_status = Column(String(20), default="active")
    
    __table_args__ = (
        CheckConstraint("flock_status IN ('active','depleted','sold','condemned')", name="check_flock_status"),
    )

class DailyFlockSnapshot(Base, AuditMixin):
    __tablename__ = "daily_flock_snapshot"
    snapshot_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.flock_id"), nullable=False)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.shed_id"), nullable=False)
    snapshot_date = Column(Date, nullable=False)
    bird_age_days = Column(Integer, nullable=False)
    flock_stage = Column(String(20), nullable=False)
    
    opening_bird_count = Column(Integer, nullable=False)
    mortality_count = Column(Integer, default=0)
    culled_sick_count = Column(Integer, default=0)
    other_movements_count = Column(Integer, default=0)
    arrivals_count = Column(Integer, default=0)
    closing_bird_count = Column(Integer, nullable=False)
    
    eggs_collected = Column(Integer, default=0)
    eggs_broken = Column(Integer, default=0)
    eggs_floor = Column(Integer, default=0)
    eggs_saleable = Column(Integer)
    hdp_percent = Column(Numeric(6, 3))

    reported_by_name = Column(String(200), nullable=False)
    reported_by_login = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)
    
    validation_flags = Column(JSONB, default=list)
