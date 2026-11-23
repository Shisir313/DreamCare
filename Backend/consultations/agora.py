"""Agora RTC token generation engine (ADR 0002).

Issues short-lived HMAC-SHA256 authenticated RTC channel tokens
for video consultations between patients and dermatologists.
"""

import base64
import hashlib
import hmac
import time


def generate_agora_rtc_token(
    app_id: str,
    app_certificate: str,
    channel_name: str,
    uid: int,
    expire_seconds: int = 3600,
    role: int = 1,
) -> str:
    """Generate Agora RTC Token using HMAC-SHA256 signature."""
    current_time = int(time.time())
    privilege_expired_ts = current_time + expire_seconds

    # Message payload: app_id + channel_name + uid + role + expired_ts
    message = f"{app_id}{channel_name}{uid}{role}{privilege_expired_ts}".encode()
    signature = hmac.new(app_certificate.encode("utf-8"), message, hashlib.sha256).digest()

    sig_b64 = base64.b64encode(signature).decode("utf-8")
    token_str = f"1:{app_id}:{sig_b64}:{privilege_expired_ts}:{uid}:{channel_name}"
    return base64.b64encode(token_str.encode("utf-8")).decode("utf-8")
