import os
import uuid
from datetime import datetime
from app.core.celery_app import celery_app
from app.db.session import SessionLocal
from app.db.models import AnalysisJob, AIResult, JobStatus, UserProfile, ProfileHistory
from app.services.storage import storage_service
from app.services.transcription import transcription_service
from app.services.ai_models import nlp_analysis_service

@celery_app.task(name="app.worker.tasks.process_audio_task")
def process_audio_task(job_id: str):
    """
    Background worker task:
    1. Fetch AnalysisJob from PostgreSQL.
    2. Download audio file from MinIO.
    3. Generate text transcript via Whisper / TranscriptionService.
    4. Perform Gemini Flash NLP Analysis (summary, sentiment, keywords).
    5. Save transcript & insights to AIResult table and mark job COMPLETED.
    6. Trigger implicit profile updater background task.
    """
    db = SessionLocal()
    try:
        job_uuid = uuid.UUID(job_id)
        job = db.query(AnalysisJob).filter(AnalysisJob.id == job_uuid).first()
        if not job:
            print(f"[Worker Error] Job {job_id} not found.")
            return False

        # 1. Update status to PROCESSING
        job.status = JobStatus.PROCESSING
        db.commit()
        print(f"[Worker] Job {job_id} is now PROCESSING.")

        # 2. Fetch audio file from MinIO storage
        print(f"[Worker] Fetching audio file '{job.file_url}' from MinIO...")
        audio_bytes = storage_service.download_file(job.file_url)
        print(f"[Worker] Downloaded {len(audio_bytes)} bytes from MinIO.")

        # 3. Speech-to-Text transcription via Whisper
        filename = os.path.basename(job.file_url)
        print(f"[Worker] Transcribing audio with Whisper service ({filename})...")
        transcript = transcription_service.transcribe_audio(audio_bytes, filename=filename)
        print(f"[Worker] Transcript generated: {transcript[:100]}...")

        # 4. Gemini Flash NLP Analysis
        print(f"[Worker] Running Gemini Flash NLP Analysis on transcript...")
        insights = nlp_analysis_service.analyze_transcript(transcript)
        print(f"[Worker] Insights extracted: sentiment='{insights.get('sentiment')}', keywords={insights.get('keywords')}")

        # 5. Save result in AIResult table
        ai_result = db.query(AIResult).filter(AIResult.job_id == job.id).first()
        if not ai_result:
            ai_result = AIResult(
                job_id=job.id,
                transcription=transcript,
                insights=insights
            )
            db.add(ai_result)
        else:
            ai_result.transcription = transcript
            ai_result.insights = insights

        # 6. Update status to COMPLETED
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        db.commit()
        print(f"[Worker] Job {job_id} successfully COMPLETED with transcription and insights saved.")

        # 7. Trigger implicit profile update task
        try:
            update_user_profile_task.delay(str(job.user_id))
        except Exception as p_err:
            print(f"[Warning] Failed to trigger update_user_profile_task: {p_err}")

        return True
    except Exception as e:
        db.rollback()
        print(f"[Worker Error] Exception processing job {job_id}: {e}")
        try:
            job = db.query(AnalysisJob).filter(AnalysisJob.id == uuid.UUID(job_id)).first()
            if job:
                job.status = JobStatus.FAILED
                db.commit()
        except Exception:
            pass
        raise e
    finally:
        db.close()

@celery_app.task(name="app.worker.tasks.process_text_task")
def process_text_task(job_id: str):
    """
    Background worker task for text-only jobs:
    1. Fetch AnalysisJob from PostgreSQL.
    2. Set status to PROCESSING.
    3. Pass text_prompt directly to Gemini Flash NLP analysis (bypassing MinIO & Whisper).
    4. Save insights & text_prompt to AIResult table and mark job COMPLETED.
    5. Trigger implicit profile updater background task.
    """
    db = SessionLocal()
    try:
        job_uuid = uuid.UUID(job_id)
        job = db.query(AnalysisJob).filter(AnalysisJob.id == job_uuid).first()
        if not job:
            print(f"[Worker Error] Job {job_id} not found.")
            return False

        # 1. Update status to PROCESSING
        job.status = JobStatus.PROCESSING
        db.commit()
        print(f"[Worker] Text Job {job_id} is now PROCESSING.")

        # 2. Gemini Flash NLP Analysis directly on text_prompt (bypassing MinIO & Whisper)
        print(f"[Worker] Running Gemini Flash NLP Analysis directly on text prompt...")
        text_content = job.text_prompt or ""
        insights = nlp_analysis_service.analyze_transcript(text_content)
        print(f"[Worker] Text Insights extracted: sentiment='{insights.get('sentiment')}', keywords={insights.get('keywords')}")

        # 3. Save result in AIResult table
        ai_result = db.query(AIResult).filter(AIResult.job_id == job.id).first()
        if not ai_result:
            ai_result = AIResult(
                job_id=job.id,
                transcription=text_content,
                insights=insights
            )
            db.add(ai_result)
        else:
            ai_result.transcription = text_content
            ai_result.insights = insights

        # 4. Update status to COMPLETED
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        db.commit()
        print(f"[Worker] Text Job {job_id} successfully COMPLETED with insights saved.")

        # 5. Trigger implicit profile update task
        try:
            update_user_profile_task.delay(str(job.user_id))
        except Exception as p_err:
            print(f"[Warning] Failed to trigger update_user_profile_task: {p_err}")

        return True
    except Exception as e:
        db.rollback()
        print(f"[Worker Error] Exception processing text job {job_id}: {e}")
        try:
            job = db.query(AnalysisJob).filter(AnalysisJob.id == uuid.UUID(job_id)).first()
            if job:
                job.status = JobStatus.FAILED
                db.commit()
        except Exception:
            pass
        raise e
    finally:
        db.close()

@celery_app.task(name="app.worker.tasks.update_user_profile_task")
def update_user_profile_task(user_id: str):
    """
    Implicit Profile Learning Task:
    1. Fetch recent journal entries for user.
    2. Pass entries & existing profile state to Gemini Flash analyzer.
    3. Update dynamic_state JSONB and recovery_phase in UserProfile table.
    """
    db = SessionLocal()
    try:
        u_uuid = uuid.UUID(user_id)
        profile = db.query(UserProfile).filter(UserProfile.user_id == u_uuid).first()
        if not profile:
            profile = UserProfile(
                user_id=u_uuid,
                onboarding_data={"what_brings_you": "Default Onboarding", "main_goals": ["Growth"], "biggest_triggers": ["Stress"]},
                dynamic_state={"current_mood_trend": "stable", "active_triggers": ["stress"], "current_focus": ["growth"]},
                recovery_phase="early_recovery"
            )
            db.add(profile)
            db.commit()
            db.refresh(profile)

        # Fetch recent completed jobs for user
        jobs = (
            db.query(AnalysisJob)
            .filter(AnalysisJob.user_id == u_uuid, AnalysisJob.status == JobStatus.COMPLETED)
            .order_by(AnalysisJob.created_at.desc())
            .limit(5)
            .all()
        )

        entries = []
        for j in jobs:
            summary = None
            sentiment = None
            if j.result:
                if j.result.insights and isinstance(j.result.insights, dict):
                    summary = j.result.insights.get("summary")
                    sentiment = j.result.insights.get("sentiment")
                if not summary and j.result.transcription:
                    summary = j.result.transcription[:150]
            if not summary and j.text_prompt:
                summary = j.text_prompt[:150]

            if summary:
                entries.append({
                    "summary": summary,
                    "sentiment": sentiment or "neutral",
                    "date": j.created_at.strftime("%Y-%m-%d") if j.created_at else ""
                })

        existing_dict = {
            "onboarding_data": profile.onboarding_data,
            "dynamic_state": profile.dynamic_state,
            "recovery_phase": profile.recovery_phase
        }

        analysis_res = nlp_analysis_service.analyze_and_update_profile(entries, existing_dict)
        if analysis_res and "dynamic_state" in analysis_res:
            profile.dynamic_state = analysis_res["dynamic_state"]
            if "recovery_phase" in analysis_res:
                profile.recovery_phase = analysis_res["recovery_phase"]
            profile.updated_at = datetime.utcnow()

            # Record time-series audit trail snapshot in ProfileHistory
            history_snapshot = ProfileHistory(
                user_id=profile.user_id,
                profile_id=profile.id,
                dynamic_state_snapshot=profile.dynamic_state,
                recovery_phase_snapshot=profile.recovery_phase
            )
            db.add(history_snapshot)
            db.commit()
            print(f"[Worker] Updated dynamic user profile & recorded history snapshot for user {user_id}: mood='{profile.dynamic_state.get('current_mood_trend')}', focus={profile.dynamic_state.get('current_focus')}")

        return True
    except Exception as e:
        db.rollback()
        print(f"[Worker Error] Error updating profile for user {user_id}: {e}")
        return False
    finally:
        db.close()
