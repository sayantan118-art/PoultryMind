# apps/api/models/vaccine.py
from sqlalchemy import Column, String, Integer, ForeignKey, Date, Boolean, Decimal, CheckConstraint, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, AuditMixin
from datetime import datetime

class VaccineScheduleTemplate(Base, AuditMixin):
    __tablename__ = "vaccine_schedule_template"
    template_name = Column(String(200), nullable=False)
    breed_id = Column(UUID(as_uuid=True), ForeignKey("breed.id"), nullable=False)
    version_number = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    superseded_by = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_template.id"))
    change_reason = Column(String)

class VaccineScheduleItem(Base, AuditMixin):
    __tablename__ = "vaccine_schedule_item"
    template_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_template.id"), nullable=False)
    sequence_number = Column(Integer, nullable=False)
    vaccine_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_master.id"), nullable=False)
    target_day = Column(Integer, nullable=False)
    flexibility_window_days = Column(Integer, default=3)
    method = Column(String(50))
    dose_ml_per_bird = Column(Decimal(8, 4))
    is_mandatory = Column(Boolean, default=True)
    grace_days_before_escalate = Column(Integer, default=1)
    post_vaccine_watch_days = Column(Integer, default=7)
    worker_instructions = Column(String)

class VaccineEvent(Base, AuditMixin):
    __tablename__ = "vaccine_event"
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.id"), nullable=False)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.id"), nullable=False)
    shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.id"), nullable=False)
    schedule_item_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_schedule_item.id"), nullable=True)
    is_adhoc = Column(Boolean, default=False)
    vaccine_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_master.id"), nullable=False)
    event_type = Column(String(30), nullable=False)
    
    target_date = Column(Date, nullable=False)
    earliest_acceptable = Column(Date)
    latest_acceptable = Column(Date)
    
    actual_date = Column(Date)
    actual_method = Column(String(50))
    batch_number = Column(String(100))
    coverage_percent = Column(Decimal(5, 2))
    status = Column(String(30), default="scheduled")
    status_updated_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("status IN ('scheduled','upcoming','due_today','administered','overdue','critically_overdue','skipped','rescheduled')", name="check_vaccine_status"),
    )
