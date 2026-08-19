from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models import User, AnalysisJob, ChatMessage, JobStatus, UserProfile
from app.api.dependencies import get_current_user
from app.services.ai_models import nlp_analysis_service
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse, ChatHistoryResponse

router = APIRouter()

@router.post("/message", response_model=ChatMessageResponse, status_code=status.HTTP_201_CREATED)
def send_chat_message(
    payload: ChatMessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Accepts a user's conversational message, injects their recent journal history as context into Gemini,
    and returns an empathetic, AI-driven coaching response.
    """
    if not payload.message or not payload.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message content cannot be empty."
        )

    # 1. Fetch recent journal context (last 5 completed jobs with results)
    recent_jobs = (
        db.query(AnalysisJob)
        .filter(
            AnalysisJob.user_id == current_user.id,
            AnalysisJob.status == JobStatus.COMPLETED
        )
        .order_by(AnalysisJob.created_at.desc())
        .limit(5)
        .all()
    )

    journal_contexts = []
    for job in recent_jobs:
        summary = None
        sentiment = None
        if job.result:
            if job.result.insights and isinstance(job.result.insights, dict):
                summary = job.result.insights.get("summary")
                sentiment = job.result.insights.get("sentiment")
            if not summary and job.result.transcription:
                summary = job.result.transcription[:150]
        if not summary and job.text_prompt:
            summary = job.text_prompt[:150]

        if summary:
            journal_contexts.append({
                "summary": summary,
                "sentiment": sentiment or "neutral",
                "date": job.created_at.strftime("%Y-%m-%d") if job.created_at else ""
            })

    # 2. Save user message in DB
    user_msg = ChatMessage(
        user_id=current_user.id,
        role="user",
        content=payload.message.strip()
    )
    db.add(user_msg)
    db.commit()
    db.refresh(user_msg)

    # Fetch UserProfile context
    profile_record = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    user_profile_dict = None
    if profile_record:
        user_profile_dict = {
            "onboarding_data": profile_record.onboarding_data,
            "dynamic_state": profile_record.dynamic_state,
            "recovery_phase": profile_record.recovery_phase
        }

    # 3. Generate empathetic AI coaching response using Gemini Flash
    coaching_res = nlp_analysis_service.generate_coaching_response(
        user_message=payload.message.strip(),
        journal_contexts=journal_contexts,
        user_profile=user_profile_dict
    )

    assistant_reply_text = coaching_res.get("content", "")
    is_crisis = coaching_res.get("is_crisis", False)

    emergency_resources = None
    if is_crisis:
        emergency_resources = {
            "saudi_health_center": "937",
            "saudi_emergency_police": "999",
            "us_crisis_lifeline": "988",
            "befrienders_international": "https://www.befrienders.org",
            "disclaimer": "Your safety is our top priority. Immediate human support is available 24/7."
        }

    # 4. Save assistant reply in DB
    assistant_msg = ChatMessage(
        user_id=current_user.id,
        role="assistant",
        content=assistant_reply_text
    )
    db.add(assistant_msg)
    db.commit()
    db.refresh(assistant_msg)

    return ChatMessageResponse(
        id=assistant_msg.id,
        role=assistant_msg.role,
        content=assistant_msg.content,
        is_crisis=is_crisis,
        emergency_resources=emergency_resources,
        created_at=assistant_msg.created_at
    )

@router.get("/history", response_model=ChatHistoryResponse)
def get_chat_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves previous chat message logs for the user session.
    """
    messages = (
        db.query(ChatMessage)
        .filter(ChatMessage.user_id == current_user.id)
        .order_by(ChatMessage.created_at.asc())
        .all()
    )

    return ChatHistoryResponse(messages=messages)
