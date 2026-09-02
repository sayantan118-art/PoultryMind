# apps/api/models/intelligence.py
import uuid
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Date
from sqlalchemy.dialects.postgresql import UUID, JSONB
from .base import Base, AuditMixin

class SystemAlert(Base, AuditMixin):
    __tablename__ = "system_alert"
    alert_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=True)
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.flock_id"), nullable=True)
    alert_level = Column(String(20), nullable=False)
    alert_type = Column(String(100), nullable=False)
    title = Column(String(300), nullable=False)
    body = Column(String, nullable=False)
    action_required = Column(Boolean, default=False)
    target_role = Column(String(20), default="owner")
    read_at = Column(DateTime)
    acknowledged_at = Column(DateTime)

class IntelligenceFlag(Base, AuditMixin):
    __tablename__ = "intelligence_flag"
    flag_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=True)
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.flock_id"), nullable=True)
    snapshot_id = Column(UUID(as_uuid=True), ForeignKey("daily_flock_snapshot.snapshot_id"), nullable=True)
    flag_type = Column(String(100), nullable=False)
    severity = Column(String(20), nullable=False)
    triggered_at = Column(Date, nullable=False)
    investigation = Column(JSONB, nullable=False, default={})
