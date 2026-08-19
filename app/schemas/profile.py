from datetime import datetime
from typing import Optional, List, Dict, Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict

class OnboardingCreate(BaseModel):
    what_brings_you: str
    main_goals: List[str]
    biggest_triggers: List[str]
    additional_answers: Optional[Dict[str, Any]] = None

class RecalibrationCreate(BaseModel):
    feel_better_or_worse: str  # e.g. "better", "worse", "same"
    updated_goals: Optional[List[str]] = None
    notes: Optional[str] = None

class DynamicStateSchema(BaseModel):
    current_mood_trend: str  # "improving", "declining", "stable"
    active_triggers: List[str]
    current_focus: List[str]

class ProfileAnalysisSchema(BaseModel):
    dynamic_state: DynamicStateSchema
    recovery_phase: str  # "early_recovery", "maintenance", "crisis_watch"

class UserProfileResponse(BaseModel):
    id: UUID
    user_id: UUID
    onboarding_data: Optional[Dict[str, Any]] = None
    dynamic_state: Optional[Dict[str, Any]] = None
    recovery_phase: str
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ProfileHistoryResponse(BaseModel):
    id: UUID
    user_id: UUID
    profile_id: UUID
    dynamic_state_snapshot: Dict[str, Any]
    recovery_phase_snapshot: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
