from typing import List, Optional
from pydantic import BaseModel, ConfigDict

class SupportContact(BaseModel):
    name: str
    phone: str
    description: str
    category: str  # "emergency", "mental_health", "crisis_line"
    country: str
    available_hours: str

    model_config = ConfigDict(from_attributes=True)

class CopingStrategy(BaseModel):
    title: str
    description: str
    category: str

    model_config = ConfigDict(from_attributes=True)

class SupportResourcesResponse(BaseModel):
    contacts: List[SupportContact]
    coping_strategies: List[CopingStrategy]
    disclaimer: str

    model_config = ConfigDict(from_attributes=True)
