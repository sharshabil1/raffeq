from datetime import datetime
from typing import Optional, List
from uuid import UUID
from pydantic import BaseModel, ConfigDict
from app.db.models import JobStatus

class JournalItemResponse(BaseModel):
    id: UUID
    job_type: str
    status: JobStatus
    summary: Optional[str] = None
    sentiment: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class PaginatedJournalsResponse(BaseModel):
    items: List[JournalItemResponse]
    total: int
    page: int
    size: int
    pages: int

    model_config = ConfigDict(from_attributes=True)
