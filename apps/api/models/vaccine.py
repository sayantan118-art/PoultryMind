# apps/api/models/vaccine.py
import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, Date, Boolean, Numeric, CheckConstraint, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, AuditMixin
from datetime import datetime

class VaccineScheduleTemplate(Base, AuditMixin):
    __tablename__ = "vaccine_schedule_template"
    template_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    template_name = Column(String(200), nullable=False)
    breed_id = Column(UUID(as_uuid=True), ForeignKey("breed.breed_id"), nullable=False)
    version_number = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    superseded_by = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_template.template_id"))
    change_reason = Column(String)

class VaccineScheduleItem(Base, AuditMixin):
    __tablename__ = "vaccine_schedule_item"
    item_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    template_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_template.template_id"), nullable=False)
    sequence_number = Column(Integer, nullable=False)
    vaccine_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_master.vaccine_id"), nullable=False)
    target_day = Column(Integer, nullable=False)
    flexibility_window_days = Column(Integer, default=3)
    method = Column(String(50))
    dose_ml_per_bird = Column(Numeric(8, 4))
    is_mandatory = Column(Boolean, default=True)
    grace_days_before_escalate = Column(Integer, default=1)
    post_vaccine_watch_days = Column(Integer, default=7)
    worker_instructions = Column(String)

class VaccineEvent(Base, AuditMixin):
    __tablename__ = "vaccine_event"
    event_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.flock_id"), nullable=False)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.shed_id"), nullable=False)
    schedule_item_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_item.item_id"), nullable=True)
    is_adhoc = Column(Boolean, default=False)
    vaccine_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_master.vaccine_id"), nullable=False)
    event_type = Column(String(30), nullable=False)
    
    target_date = Column(Date, nullable=False)
    earliest_acceptable = Column(Date)
    latest_acceptable = Column(Date)
    
    actual_date = Column(Date)
    actual_method = Column(String(50))
    batch_number = Column(String(100))
    coverage_percent = Column(Numeric(5, 2))
    status = Column(String(30), default="scheduled")
    status_updated_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("status IN ('scheduled','upcoming','due_today','administered','overdue','critically_overdue','skipped','rescheduled')", name="check_vaccine_status"),
    )
