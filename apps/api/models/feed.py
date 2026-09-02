# apps/api/models/feed.py
from sqlalchemy import Column, String, Integer, ForeignKey, Date, Boolean, Numeric, CheckConstraint, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, AuditMixin

class FeedFormula(Base, AuditMixin):
    __tablename__ = "feed_formula"
    formula_name = Column(String(200), nullable=False)
    formula_code = Column(String(50), nullable=False)
    flock_stage = Column(String(20), nullable=False)
    version_number = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    superseded_by = Column(UUID(as_uuid=True), ForeignKey("feed_formula.id"))
    
    __table_args__ = (
        CheckConstraint("flock_stage IN ('chick','grower','pre_layer','layer')", name="check_formula_stage"),
    )

class FeedFormulaIngredient(Base, AuditMixin):
    __tablename__ = "feed_formula_ingredient"
    formula_id = Column(UUID(as_uuid=True), ForeignKey("feed_formula.id"), nullable=False)
    formula_version = Column(Integer, nullable=False)
    raw_material_id = Column(UUID(as_uuid=True), ForeignKey("raw_material.id"), nullable=False)
    quantity_per_100kg = Column(Numeric(8, 3), nullable=False)
    is_critical = Column(Boolean, default=False)

class FeedBatch(Base, AuditMixin):
    __tablename__ = "feed_batch"
    batch_code = Column(String(50), nullable=False, unique=True)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.id"), nullable=False)
    formula_id = Column(UUID(as_uuid=True), ForeignKey("feed_formula.id"), nullable=False)
    formula_version = Column(Integer, nullable=False)
    production_date = Column(Date, nullable=False)
    quantity_kg = Column(Numeric(12, 3), nullable=False)
    quality_status = Column(String(20), default="pass")
    remaining_qty_kg = Column(Numeric(12, 3))

class FeedDispatch(Base, AuditMixin):
    __tablename__ = "feed_dispatch"
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.id"), nullable=False)
    dispatch_date = Column(Date, nullable=False)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("feed_batch.id"), nullable=False)
    to_shed_id = Column(UUID(as_uuid=True), ForeignKey("shed.id"), nullable=False)
    to_flock_id = Column(UUID(as_uuid=True), ForeignKey("flock.id"), nullable=False)
    qty_dispatched_kg = Column(Numeric(10, 3), nullable=False)
    qty_received_kg = Column(Numeric(10, 3))
