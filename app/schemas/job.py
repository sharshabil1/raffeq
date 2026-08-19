from datetime import datetime
from typing import Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict
from app.db.models import JobStatus

class TextJobCreate(BaseModel):
    text_prompt: str

class NLPAnalysisSchema(BaseModel):
    summary: str
    sentiment: str  # "positive", "negative", "neutral"
    keywords: list[str]

class JobResponse(BaseModel):
    id: UUID
    user_id: UUID
    job_type: str
    file_url: Optional[str] = None
    text_prompt: Optional[str] = None
    status: JobStatus
    created_at: datetime
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class JobStatusResponse(BaseModel):
    id: UUID
    status: JobStatus
    created_at: datetime
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class JobResultsResponse(BaseModel):
    id: UUID
    user_id: UUID
    job_type: str
    file_url: Optional[str] = None
    text_prompt: Optional[str] = None
    status: JobStatus
    created_at: datetime
    completed_at: Optional[datetime] = None
    transcription: Optional[str] = None
    insights: Optional[Dict[str, Any]] = None

    model_config = ConfigDict(from_attributes=True)
