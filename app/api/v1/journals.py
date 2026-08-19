import math
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models import User, AnalysisJob
from app.api.dependencies import get_current_user
from app.services.storage import storage_service
from app.schemas.journal import JournalItemResponse, PaginatedJournalsResponse

router = APIRouter()

@router.get("", response_model=PaginatedJournalsResponse)
def list_user_journals(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns a paginated list of all past analysis jobs/journals for the current user.
    Shows summaries and dates without heavy audio or full transcription payloads.
    """
    query = db.query(AnalysisJob).filter(AnalysisJob.user_id == current_user.id)
    total = query.count()

    pages = math.ceil(total / size) if total > 0 else 0
    offset = (page - 1) * size

    jobs = query.order_by(AnalysisJob.created_at.desc()).offset(offset).limit(size).all()

    items = []
    for job in jobs:
        summary = None
        sentiment = None

        if job.result:
            if job.result.insights and isinstance(job.result.insights, dict):
                summary = job.result.insights.get("summary")
                sentiment = job.result.insights.get("sentiment")
            
            if not summary and job.result.transcription:
                summary = job.result.transcription[:150] + "..." if len(job.result.transcription) > 150 else job.result.transcription

        if not summary and job.text_prompt:
            summary = job.text_prompt[:150] + "..." if len(job.text_prompt) > 150 else job.text_prompt

        items.append(
            JournalItemResponse(
                id=job.id,
                job_type=job.job_type,
                status=job.status,
                summary=summary,
                sentiment=sentiment,
                created_at=job.created_at,
                completed_at=job.completed_at
            )
        )

    return PaginatedJournalsResponse(
        items=items,
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.delete("/{job_id}", status_code=status.HTTP_200_OK)
def delete_user_journal(
    job_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Allows a user to securely delete a sensitive journal entry and its associated MinIO audio file for privacy.
    """
    job = db.query(AnalysisJob).filter(
        AnalysisJob.id == job_id,
        AnalysisJob.user_id == current_user.id
    ).first()

    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found."
        )

    # Delete associated audio file from MinIO if present
    if job.file_url:
        try:
            storage_service.delete_file(job.file_url)
            print(f"[Storage] Successfully deleted file '{job.file_url}' from MinIO.")
        except Exception as storage_err:
            print(f"[Warning] Error deleting MinIO file '{job.file_url}': {storage_err}")

    # Delete job record (DB cascade deletes AIResult)
    db.delete(job)
    db.commit()

    return {"detail": "Journal entry and associated storage files deleted successfully."}
