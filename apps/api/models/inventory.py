# apps/api/models/inventory.py
import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, Date, Numeric, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from .base import Base, AuditMixin

class RawMaterialStock(Base, AuditMixin):
    __tablename__ = "raw_material_stock"
    stock_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    material_id = Column(UUID(as_uuid=True), ForeignKey("raw_material.material_id"), nullable=False)
    current_stock_kg = Column(Numeric(12, 3), default=0)
    
    __table_args__ = (UniqueConstraint("farm_id", "material_id", name="uq_farm_material_stock"),)

class VaccineInventory(Base, AuditMixin):
    __tablename__ = "vaccine_inventory"
    inv_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farm.farm_id"), nullable=False)
    vaccine_id = Column(UUID(as_uuid=True), ForeignKey("vaccine_master.vaccine_id"), nullable=False)
    batch_number = Column(String(100), nullable=False)
    vials_remaining = Column(Integer, nullable=False)
    doses_remaining = Column(Integer, nullable=False)
    expiry_date = Column(Date, nullable=False)
