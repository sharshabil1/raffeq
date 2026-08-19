from datetime import datetime
from typing import List, Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict

class ChatMessageCreate(BaseModel):
    message: str

class CoachingResponseSchema(BaseModel):
    coaching_message: str
    is_crisis: bool

class ChatMessageResponse(BaseModel):
    id: UUID
    role: str
    content: str
    is_crisis: bool = False
    emergency_resources: Optional[Dict[str, Any]] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ChatHistoryResponse(BaseModel):
    messages: List[ChatMessageResponse]

    model_config = ConfigDict(from_attributes=True)
