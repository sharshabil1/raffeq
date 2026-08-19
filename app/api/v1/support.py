from typing import Optional
from fastapi import APIRouter, Query
from app.schemas.support import SupportContact, CopingStrategy, SupportResourcesResponse

router = APIRouter()

@router.get("/resources", response_model=SupportResourcesResponse)
def get_support_resources(
    country: Optional[str] = Query(None, description="Country filter (e.g. SA, US, International)")
):
    """
    Returns local emergency helpline numbers, coping hotline info, and professional support contacts.
    """
    contacts = [
        SupportContact(
            name="Saudi National Health Center Hotline (مركز بلاغات الصحة النفسية)",
            phone="937",
            description="24/7 free medical & mental health consultation and crisis support in Saudi Arabia.",
            category="mental_health",
            country="SA",
            available_hours="24/7"
        ),
        SupportContact(
            name="Saudi Emergency General Services (الطوارئ العامة)",
            phone="999",
            description="Saudi Arabia General Emergency and Police Service.",
            category="emergency",
            country="SA",
            available_hours="24/7"
        ),
        SupportContact(
            name="National Suicide & Crisis Lifeline",
            phone="988",
            description="Free, confidential 24/7 mental health and crisis support lifeline.",
            category="crisis_line",
            country="US",
            available_hours="24/7"
        ),
        SupportContact(
            name="Befrienders Worldwide (International Crisis Line Directory)",
            phone="https://www.befrienders.org",
            description="Global network of emotional support centers and crisis hotlines.",
            category="crisis_line",
            country="International",
            available_hours="24/7"
        )
    ]

    coping_strategies = [
        CopingStrategy(
            title="5-4-3-2-1 Sensory Grounding Technique",
            description="Identify 5 things you can see, 4 things you can physically touch, 3 things you can hear, 2 things you can smell, and 1 thing you can taste to anchor yourself in the present moment.",
            category="grounding"
        ),
        CopingStrategy(
            title="Box Breathing (4x4)",
            description="Inhale slowly for 4 seconds, hold your breath for 4 seconds, exhale for 4 seconds, and pause for 4 seconds. Repeat 4 times to soothe your nervous system.",
            category="breathing"
        ),
        CopingStrategy(
            title="Expressive Reflection & Micro-Journaling",
            description="Write down 3 specific thoughts currently bothering you, then next to each, write 1 actionable step or positive reframe.",
            category="reflection"
        )
    ]

    # Filter contacts if country query parameter is supplied
    if country:
        country_code = country.strip().upper()
        filtered = [c for c in contacts if c.country.upper() == country_code or c.country == "International"]
        if filtered:
            contacts = filtered

    disclaimer = (
        "IMPORTANT NOTICE: Rafeeq is an AI-assisted tool designed for self-reflection and personal growth. "
        "It is NOT a medical device, licensed therapy provider, or emergency service. If you are experiencing "
        "a mental health crisis, severe distress, or immediate harm, please contact your local emergency services or a professional healthcare provider immediately."
    )

    return SupportResourcesResponse(
        contacts=contacts,
        coping_strategies=coping_strategies,
        disclaimer=disclaimer
    )
