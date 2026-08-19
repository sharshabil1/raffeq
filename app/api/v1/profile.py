from typing import List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models import User, UserProfile, ProfileHistory
from app.api.dependencies import get_current_user
from app.schemas.profile import OnboardingCreate, UserProfileResponse, RecalibrationCreate, ProfileHistoryResponse

router = APIRouter()

@router.post("/onboarding", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
def submit_onboarding(
    payload: OnboardingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Day 1 Warm Onboarding: Saves user baseline responses (what brings you, goals, triggers).
    Initializes onboarding_data (immutable baseline) and dynamic_state, saving an initial ProfileHistory snapshot.
    """
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()

    onboarding_dict = {
        "what_brings_you": payload.what_brings_you,
        "main_goals": payload.main_goals,
        "biggest_triggers": payload.biggest_triggers,
        "additional_answers": payload.additional_answers or {}
    }

    initial_dynamic_state = {
        "current_mood_trend": "stable",
        "active_triggers": payload.biggest_triggers,
        "current_focus": payload.main_goals
    }

    if not profile:
        profile = UserProfile(
            user_id=current_user.id,
            onboarding_data=onboarding_dict,
            dynamic_state=initial_dynamic_state,
            recovery_phase="early_recovery"
        )
        db.add(profile)
    else:
        profile.onboarding_data = onboarding_dict
        if not profile.dynamic_state:
            profile.dynamic_state = initial_dynamic_state
        profile.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(profile)

    # Save initial profile history snapshot
    history_entry = ProfileHistory(
        user_id=current_user.id,
        profile_id=profile.id,
        dynamic_state_snapshot=profile.dynamic_state,
        recovery_phase_snapshot=profile.recovery_phase
    )
    db.add(history_entry)
    db.commit()

    return profile

@router.get("", response_model=UserProfileResponse)
def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves the current user's profile, including onboarding baseline and dynamic AI-learned state.
    """
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Please complete onboarding first."
        )
    return profile

@router.get("/history", response_model=List[ProfileHistoryResponse])
def get_profile_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves time-series profile history audit trail snapshots for emotional recovery evolution graphs.
    """
    history_logs = (
        db.query(ProfileHistory)
        .filter(ProfileHistory.user_id == current_user.id)
        .order_by(ProfileHistory.created_at.asc())
        .all()
    )
    return history_logs

@router.put("/recalibrate", response_model=UserProfileResponse)
def recalibrate_profile(
    payload: RecalibrationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Milestone Check-In (Day 14 / Day 30): Explicit recalibration based on user self-reflection.
    """
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Please complete onboarding first."
        )

    dynamic = profile.dynamic_state or {}

    # Recalibrate mood trend & goals based on explicit feedback
    if payload.feel_better_or_worse.lower() in ("better", "improving"):
        dynamic["current_mood_trend"] = "improving"
        profile.recovery_phase = "maintenance"
    elif payload.feel_better_or_worse.lower() in ("worse", "declining"):
        dynamic["current_mood_trend"] = "declining"
        profile.recovery_phase = "early_recovery"

    if payload.updated_goals:
        dynamic["current_focus"] = payload.updated_goals

    recalibration_log = dynamic.get("recalibrations", [])
    recalibration_log.append({
        "date": datetime.utcnow().strftime("%Y-%m-%d"),
        "feedback": payload.feel_better_or_worse,
        "notes": payload.notes or ""
    })
    dynamic["recalibrations"] = recalibration_log

    profile.dynamic_state = dynamic
    profile.updated_at = datetime.utcnow()

    # Save recalibration profile history snapshot
    history_entry = ProfileHistory(
        user_id=current_user.id,
        profile_id=profile.id,
        dynamic_state_snapshot=profile.dynamic_state,
        recovery_phase_snapshot=profile.recovery_phase
    )
    db.add(history_entry)

    db.commit()
    db.refresh(profile)
    return profile
