# apps/api/models/inventory.py
from sqlalchemy import Column, String, Integer, ForeignKey, Date, Numeric, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from .base import Base, AuditMixin

class RawMaterialStock(Base, AuditMixin):
    __tablename__ = "raw_material_stock"
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.id"), nullable=False)
    material_id = Column(UUID(as_uuid=True), ForeignKey("raw_material.id"), nullable=False)
    current_stock_kg = Column(Numeric(12, 3), default=0)
    
    __table_args__ = (UniqueConstraint("farm_id", "material_id", name="uq_farm_material_stock"),)

class VaccineInventory(Base, AuditMixin):
    __tablename__ = "vaccine_inventory"
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.id"), nullable=False)
    vaccine_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_master.id"), nullable=False)
    batch_number = Column(String(100), nullable=False)
    vials_remaining = Column(Integer, nullable=False)
    doses_remaining = Column(Integer, nullable=False)
    expiry_date = Column(Date, nullable=False)
