# apps/api/models/health.py
import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, Date, Boolean, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, AuditMixin

class HealthEvent(Base, AuditMixin):
    __tablename__ = "health_event"
    event_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.flock_id"), nullable=False)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.shed_id"), nullable=False)
    event_date = Column(Date, nullable=False)
    event_type = Column(String(50), nullable=False)
    description = Column(String, nullable=False)
    reported_by_name = Column(String(200), nullable=False)
    reported_by_login = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)

class BirdMovement(Base, AuditMixin):
    __tablename__ = "flock_bird_movement"
    movement_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.flock_id"), nullable=False)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.shed_id"), nullable=False)
    movement_date = Column(Date, nullable=False)
    movement_type = Column(String(30), nullable=False)
    direction = Column(String(5), nullable=False)
    bird_count = Column(Integer, nullable=False)
    status = Column(String(20), default="pending")
    reported_by_name = Column(String(200), nullable=False)
    reported_by_login = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)
    
    __table_args__ = (
        CheckConstraint("movement_type IN ('sold','transferred_out','condemned','theft_suspected','missing_unknown','transfer_in')", name="check_movement_type"),
        CheckConstraint("direction IN ('out','in')", name="check_movement_direction"),
        CheckConstraint("status IN ('pending','approved','rejected')", name="check_movement_status"),
    )
