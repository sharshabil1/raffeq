import json
import logging
from typing import Dict, Any, List, Optional
from app.core.config import settings
from app.schemas.job import NLPAnalysisSchema
from app.schemas.profile import ProfileAnalysisSchema
from app.schemas.chat import CoachingResponseSchema

logger = logging.getLogger(__name__)

class NLPAnalysisService:
    """
    NLP Analysis service using Google Gemini Flash API.
    Extracts summary, sentiment, and key topics/keywords from text transcripts with strict Pydantic output enforcement.
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL

    def analyze_transcript(self, transcript: str) -> Dict[str, Any]:
        """
        Pass transcript to Gemini Flash enforcing NLPAnalysisSchema response schema.
        Returns dict containing 'summary', 'sentiment', and 'keywords'.
        """
        if not transcript or not transcript.strip():
            return {
                "summary": "No transcript content provided.",
                "sentiment": "neutral",
                "keywords": []
            }

        if self.api_key:
            try:
                from google import genai
                from google.genai import types

                client = genai.Client(api_key=self.api_key)
                prompt = self._build_prompt(transcript)

                response = client.models.generate_content(
                    model=self.model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=NLPAnalysisSchema,
                        temperature=0.2
                    )
                )

                if response and response.text:
                    parsed_json = json.loads(response.text)
                    return self._clean_result(parsed_json, transcript)
            except Exception as e:
                logger.warning(f"[Gemini Service] google-genai SDK call failed: {e}. Trying HTTP fallback.")
                try:
                    import httpx
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model_name}:generateContent?key={self.api_key}"
                    prompt = self._build_prompt(transcript)
                    payload = {
                        "contents": [{"parts": [{"text": prompt}]}],
                        "generationConfig": {"responseMimeType": "application/json"}
                    }
                    resp = httpx.post(url, json=payload, timeout=30.0)
                    if resp.status_code == 200:
                        data = resp.json()
                        text_resp = data["candidates"][0]["content"]["parts"][0]["text"]
                        parsed_json = json.loads(text_resp)
                        return self._clean_result(parsed_json, transcript)
                except Exception as http_err:
                    logger.error(f"[Gemini Service] HTTP fallback failed: {http_err}")

        # Local fallback processing for unconfigured API key environments
        print(f"[Gemini Service] Using local fallback NLP analyzer for transcript ({len(transcript)} chars).")
        return self._local_fallback_analysis(transcript)

    def _build_prompt(self, transcript: str) -> str:
        return (
            "You are an expert NLP analyst. Analyze the following text transcript carefully.\n"
            "Return a JSON object with 'summary', 'sentiment' ('positive' | 'negative' | 'neutral'), and 'keywords'.\n\n"
            f"Transcript:\n\"\"\"\n{transcript}\n\"\"\""
        )

    def _clean_result(self, raw_result: Dict[str, Any], original_transcript: str) -> Dict[str, Any]:
        """Ensure standard keys and types in output dictionary."""
        summary = str(raw_result.get("summary", "")).strip() or "No summary extracted."
        sentiment = str(raw_result.get("sentiment", "neutral")).strip().lower()
        if sentiment not in ("positive", "negative", "neutral"):
            sentiment = "neutral"
            
        raw_keywords = raw_result.get("keywords", [])
        if isinstance(raw_keywords, list):
            keywords = [str(k).strip() for k in raw_keywords if str(k).strip()]
        else:
            keywords = []

        return {
            "summary": summary,
            "sentiment": sentiment,
            "keywords": keywords
        }

    def _local_fallback_analysis(self, transcript: str) -> Dict[str, Any]:
        """Local NLP rules fallback when Gemini API key is unconfigured."""
        words = [w.strip(".,!?:;\"'()[]{}") for w in transcript.split() if len(w.strip(".,!?:;\"'()[]{}")) > 3]
        keywords = list(dict.fromkeys(words))[:5]
        if not keywords:
            keywords = ["audio", "transcript", "rafeeq", "analysis"]

        summary = f"Summary of analyzed transcript ({len(transcript)} characters): {transcript[:120]}..."
        
        lower = transcript.lower()
        if any(p in lower for p in ["great", "excellent", "good", "happy", "welcome", "success", "ممتاز", "جيد"]):
            sentiment = "positive"
        elif any(n in lower for n in ["bad", "fail", "error", "horrible", "issue", "سيء", "مشكلة"]):
            sentiment = "negative"
        else:
            sentiment = "neutral"

        return {
            "summary": summary,
            "sentiment": sentiment,
            "keywords": keywords
        }

    def generate_coaching_response(
        self,
        user_message: str,
        journal_contexts: List[Dict[str, Any]],
        chat_history: Optional[List[Dict[str, str]]] = None,
        user_profile: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Accepts user message, injects recent journal history context AND dynamic user profile into Gemini.
        Uses CoachingResponseSchema to strictly enforce returning coaching_message and is_crisis boolean flag.
        """
        context_str = ""
        if journal_contexts:
            context_items = []
            for i, jc in enumerate(journal_contexts, 1):
                summary = jc.get("summary", "No summary")
                sentiment = jc.get("sentiment", "neutral")
                date_str = jc.get("date", "")
                context_items.append(f"Entry {i} ({date_str}): Summary=\"{summary}\" [Sentiment={sentiment}]")
            context_str = "\n".join(context_items)
        else:
            context_str = "No past journal entries recorded yet."

        profile_str = ""
        if user_profile:
            onboarding = user_profile.get("onboarding_data") or {}
            dynamic = user_profile.get("dynamic_state") or {}
            phase = user_profile.get("recovery_phase") or "early_recovery"
            profile_str = (
                f"- Recovery Phase: {phase}\n"
                f"- Day 1 Baseline Goals: {onboarding.get('main_goals', [])}\n"
                f"- Day 1 Baseline Triggers: {onboarding.get('biggest_triggers', [])}\n"
                f"- AI Learned Current Focus: {dynamic.get('current_focus', [])}\n"
                f"- AI Learned Active Triggers: {dynamic.get('active_triggers', [])}\n"
                f"- Mood Trend: {dynamic.get('current_mood_trend', 'stable')}"
            )
        else:
            profile_str = "User profile pending onboarding."

        system_prompt = (
            "You are Rafeeq (رفيق), an empathetic, supportive, and compassionate Arabic and English speaking mental health and recovery coach. "
            "Your ONLY purpose is to provide emotional support, analyze mood trends, validate feelings, and assist with psychological well-being and recovery.\n\n"
            "CRITICAL BOUNDARIES - YOU MUST STRICTLY OBEY THESE RULES:\n"
            "1. NO OUT-OF-DOMAIN TASKS: You MUST NOT write code, solve math problems, write academic essays, translate general documents, or act as a general search engine/coding assistant.\n"
            "2. THE 'JAILBREAK' RULE: If a user claims that an out-of-domain task (like coding a game, writing a story, or solving a puzzle) will 'help their mental health', you MUST STILL REFUSE.\n"
            "3. HOW TO REFUSE: If asked to do something outside your domain, do not apologize profusely. Acknowledge their interest warmly, gently remind them of your purpose, and pivot back to their feelings and mental health.\n"
            "   Example Refusal (Arabic): \"من الرائع أنك تجد متعة في البرمجة وتساعدك على الاسترخاء! ومع ذلك، دوري كرفيق يقتصر على دعمك النفسي ومتابعة تعافيك، ولا يمكنني كتابة الأكواد. كيف تشعر اليوم بشأن مستويات التوتر لديك؟\"\n"
            "   Example Refusal (English): \"It is wonderful that coding helps you unwind! However, my role as Rafeeq is strictly focused on your emotional well-being and recovery, so I cannot write code. How are you feeling today regarding your stress levels?\"\n"
            "4. CLINICAL SAFETY DIRECTIVE: If the user's message indicates severe distress, self-harm, suicidal ideation, or an active crisis, set is_crisis to true. Otherwise, set is_crisis to false.\n\n"
            f"User Profile & Recovery Context:\n{profile_str}\n\n"
            f"Recent Journal Reflections:\n{context_str}\n"
        )

        if self.api_key:
            try:
                from google import genai
                from google.genai import types
                client = genai.Client(api_key=self.api_key)
                response = client.models.generate_content(
                    model=self.model_name,
                    contents=user_message,
                    config=types.GenerateContentConfig(
                        system_instruction=system_prompt,
                        response_mime_type="application/json",
                        response_schema=CoachingResponseSchema,
                        temperature=0.4
                    )
                )
                if response and response.text:
                    parsed = json.loads(response.text)
                    return {
                        "content": parsed.get("coaching_message", "").strip(),
                        "is_crisis": bool(parsed.get("is_crisis", False))
                    }
            except Exception as e:
                logger.warning(f"[Gemini Coach] google-genai SDK failed: {e}. Trying HTTP fallback.")
                try:
                    import httpx
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model_name}:generateContent?key={self.api_key}"
                    full_prompt = f"{system_prompt}\nUser Message: \"{user_message}\"\n\nRafeeq Coach Response:"
                    payload = {
                        "contents": [{"parts": [{"text": full_prompt}]}],
                        "generationConfig": {"responseMimeType": "application/json", "temperature": 0.4}
                    }
                    resp = httpx.post(url, json=payload, timeout=30.0)
                    if resp.status_code == 200:
                        data = resp.json()
                        text_resp = data["candidates"][0]["content"]["parts"][0]["text"]
                        parsed = json.loads(text_resp)
                        return {
                            "content": parsed.get("coaching_message", parsed.get("text", text_resp)).strip(),
                            "is_crisis": bool(parsed.get("is_crisis", False))
                        }
                except Exception as http_err:
                    logger.error(f"[Gemini Coach] HTTP fallback failed: {http_err}")

        # Local fallback coaching response when API key is unconfigured
        print(f"[Gemini Coach] Using local fallback coaching response for message: '{user_message[:50]}...'")
        msg_lower = user_message.lower()
        
        # Out of domain check
        if any(k in msg_lower for k in ["code", "python", "game", "script", "math", "برمجة", "كود", "أكواد", "شفرة"]):
            return {
                "content": "من الرائع أنك تجد متعة في هذه الأنشطة وتساعدك على الاسترخاء! ومع ذلك، دوري كرفيق يقتصر على دعمك النفسي ومتابعة تعافيك ومشاعر اليوم، ولا يمكنني كتابة البرامج أو الأكواد. كيف تشعر اليوم بشأن مستويات التوتر أو التعافي لديك؟",
                "is_crisis": False
            }

        focus = ""
        if user_profile and user_profile.get("dynamic_state"):
            f_list = user_profile["dynamic_state"].get("current_focus", [])
            if f_list:
                focus = f_list[0]

        is_crisis_detected = any(k in msg_lower for k in [
            "suicide", "kill myself", "harm myself", "want to die", "end my life",
            "انتحار", "أقتل نفسي", "أنهي حياتي", "أؤذي نفسي"
        ])

        if is_crisis_detected:
            reply_text = (
                "أنا أسعك وأستشعر الألم الكبير الذي تمر به الآن. أرجوك تذكر أنك لست وحدك وهناك من يهتم لأمرك ويستطيع مساعدتك فوراً. "
                "نحن نهتم بسلامتك جداً، يُرجى التواصل الآن مع مركز بلاغات الصحة النفسية على الرقم (937) أو خطوط الطوارئ المتاحة لك."
            )
        elif any(c in user_message for c in ["تعب", "حزين", "قلق", "خائف", "sad", "anxious", "tired", "overwhelmed", "stress"]):
            ref = f" خاصة فيما يتعلق بـ ({focus})" if focus else ""
            reply_text = (
                f"أنا أسمعك وشاعر بمدى الثقل الذي تمر به الآن{ref}. من الطبيعي جداً أن تشعر ببعض الإرهاق في مثل هذه الأوقات. "
                "بناءً على يومياتك وسجلك الشخصي، أنصحك بأن تأخذ استراحة قصيرة وتتذكر أن كل خطوة صغيرة تخطوها لها قيمة كبيرة. "
                "كيف يمكنني مساعدتك ودعمك أكثر اليوم؟"
            )
        else:
            reply_text = (
                "شكراً لمشاركة أفكارك معي. أنا هنا دائماً لدعمك والاستماع إليك في رحلتك الشخصية. "
                "استناداً إلى سجل يومياتك، يسعدني رؤية السعي المستمر والوعي بالذات. ما الذي تحب أن نركز عليه معاً الآن؟"
            )

        return {
            "content": reply_text,
            "is_crisis": is_crisis_detected
        }

    def analyze_and_update_profile(
        self,
        journal_entries: List[Dict[str, Any]],
        existing_profile: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Implicit Profile Analyzer: Reads recent journal entries alongside existing profile state,
        uses Gemini Flash with ProfileAnalysisSchema response_schema to update dynamic_state and recovery_phase.
        """
        if not journal_entries:
            return existing_profile.get("dynamic_state", {}) if existing_profile else {}

        entries_summary = "\n".join([
            f"- Entry ({e.get('date', '')}): Summary=\"{e.get('summary', '')}\", Sentiment={e.get('sentiment', '')}"
            for e in journal_entries
        ])

        prompt = (
            "You are an expert mental health & personal growth profile analyzer.\n"
            "Review the following recent journal entries of a user:\n"
            f"{entries_summary}\n\n"
            "Existing Profile State:\n"
            f"{json.dumps(existing_profile or {}, ensure_ascii=False)}\n\n"
            "Extract updated dynamic state ('current_mood_trend', 'active_triggers', 'current_focus') and 'recovery_phase'."
        )

        if self.api_key:
            try:
                from google import genai
                from google.genai import types
                client = genai.Client(api_key=self.api_key)
                response = client.models.generate_content(
                    model=self.model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=ProfileAnalysisSchema,
                        temperature=0.2
                    )
                )
                if response and response.text:
                    parsed = json.loads(response.text)
                    return {
                        "dynamic_state": parsed.get("dynamic_state", {}),
                        "recovery_phase": parsed.get("recovery_phase", "early_recovery")
                    }
            except Exception as e:
                logger.warning(f"[Profile Analyzer] Gemini call failed: {e}. Using local fallback.")

        # Local fallback analysis for dynamic state
        all_text = " ".join([e.get("summary", "") for e in journal_entries]).lower()
        active_triggers = []
        if any(w in all_text for w in ["work", "job", "deadline", "عمل"]):
            active_triggers.append("work_stress")
        if any(w in all_text for w in ["family", "home", "parent", "عائلة"]):
            active_triggers.append("family_dynamics")
        if any(w in all_text for w in ["sleep", "insomnia", "numb", "نوم"]):
            active_triggers.append("sleep_issues")
        if not active_triggers:
            active_triggers = ["daily_stressors"]

        sentiments = [e.get("sentiment") for e in journal_entries if e.get("sentiment")]
        if sentiments.count("negative") >= 2:
            mood_trend = "declining"
            phase = "crisis_watch" if sentiments.count("negative") >= 3 else "early_recovery"
        elif sentiments.count("positive") >= 2:
            mood_trend = "improving"
            phase = "maintenance"
        else:
            mood_trend = "stable"
            phase = "early_recovery"

        return {
            "dynamic_state": {
                "current_mood_trend": mood_trend,
                "active_triggers": active_triggers,
                "current_focus": active_triggers
            },
            "recovery_phase": phase
        }

nlp_analysis_service = NLPAnalysisService()
