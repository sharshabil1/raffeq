import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models import User, AnalysisJob, JobStatus
from app.api.dependencies import get_current_user
from app.services.storage import storage_service
from app.schemas.job import JobResponse, JobStatusResponse, JobResultsResponse, TextJobCreate
from app.worker.tasks import process_audio_task, process_text_task

router = APIRouter()

@router.post("/upload", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def upload_audio_job(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Upload an audio file for AI processing.
    1. Authenticate user.
    2. Upload file stream to MinIO.
    3. Persist AnalysisJob in DB with status PENDING.
    4. Queue process_audio_task background Celery task.
    """
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No filename provided."
        )

    # 1. Create unique object name for MinIO
    file_ext = file.filename.split(".")[-1] if "." in file.filename else "file"
    unique_filename = f"{uuid.uuid4()}.{file_ext}"
    object_name = f"audio/{current_user.id}/{unique_filename}"

    # 2. Upload file stream to MinIO
    try:
        stored_object_name = storage_service.upload_file(
            file_data=file.file,
            object_name=object_name,
            content_type=file.content_type or "application/octet-stream"
        )
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload audio file to storage: {err}"
        )

    # 3. Create AnalysisJob record in PostgreSQL
    job = AnalysisJob(
        user_id=current_user.id,
        job_type="audio",
        file_url=stored_object_name,
        status=JobStatus.PENDING
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    # 4. Dispatch Celery task
    try:
        process_audio_task.delay(str(job.id))
    except Exception as task_err:
        print(f"[Warning] Failed to queue Celery task: {task_err}")

    return job

@router.post("/text", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def submit_text_job(
    payload: TextJobCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Submit a text prompt directly for AI processing (bypassing MinIO & Whisper).
    1. Authenticate user.
    2. Persist AnalysisJob with job_type="text" and text_prompt.
    3. Queue process_text_task background Celery task.
    """
    if not payload.text_prompt or not payload.text_prompt.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="text_prompt cannot be empty."
        )

    # 1. Create AnalysisJob record in PostgreSQL
    job = AnalysisJob(
        user_id=current_user.id,
        job_type="text",
        text_prompt=payload.text_prompt,
        status=JobStatus.PENDING
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    # 2. Dispatch Celery task
    try:
        process_text_task.delay(str(job.id))
    except Exception as task_err:
        print(f"[Warning] Failed to queue Celery text task: {task_err}")

    return job

@router.get("/{job_id}/status", response_model=JobStatusResponse)
def get_job_status(
    job_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Check processing status of a job (for Flutter client polling).
    Returns id, status, created_at, completed_at.
    """
    job = db.query(AnalysisJob).filter(
        AnalysisJob.id == job_id,
        AnalysisJob.user_id == current_user.id
    ).first()

    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found."
        )

    return job

@router.get("/{job_id}/results", response_model=JobResultsResponse)
def get_job_results(
    job_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieve final job results joined with AIResult data.
    Returns job details, transcription, and insights JSON (summary, sentiment, keywords).
    """
    job = db.query(AnalysisJob).filter(
        AnalysisJob.id == job_id,
        AnalysisJob.user_id == current_user.id
    ).first()

    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found."
        )

    transcription = job.result.transcription if job.result else None
    insights = job.result.insights if job.result else None

    return JobResultsResponse(
        id=job.id,
        user_id=job.user_id,
        job_type=job.job_type,
        file_url=job.file_url,
        text_prompt=job.text_prompt,
        status=job.status,
        created_at=job.created_at,
        completed_at=job.completed_at,
        transcription=transcription,
        insights=insights
    )
