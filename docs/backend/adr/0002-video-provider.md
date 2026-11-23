# ADR 002: Video Consultation Hosted Provider Selection

## Status
Accepted

## Context
DermaCare requires secure, compliant, high-availability 1-on-1 video consultations between verified dermatologists and patients across urban and rural connectivity in Nepal (3G/4G cellular networks, varying bandwidth). The backend must issue short-lived, cryptographically signed room tokens while offloading WebRTC media streaming to a battle-tested hosted provider (no self-hosted custom WebRTC server maintenance).

## Comparison of Providers

| Criteria | Agora (Agora.io RTC) | Daily (Daily.co) | Jitsi (Jitsi as a Service - 8x8) |
| :--- | :--- | :--- | :--- |
| **Token Model** | Token server SDK generates short-lived RTC tokens using App ID and Certificate; channel-based. | REST API creates private room with expiration, issues short-lived meeting tokens. | JWT token signed with tenant private key; room-scoped. |
| **Flutter SDK** | First-class official Flutter SDK (`agora_rtc_engine`), widely tested across Android/iOS in South Asia. | Flutter wrapper available, but primarily web/React native focused. | `jitsi_meet_flutter_sdk`, varying maintenance track record. |
| **Bandwidth Adaptability** | Industry-leading low-bandwidth adaptation (dynamic video resolution, aggressive audio priority, AV1/H.264 fallback). | Good, WebRTC SFU-based, but sensitive to packet drops on flaky mobile data. | Moderate; heavier resource consumption on entry-level Android devices. |
| **Pricing & Free Tier** | 10,000 free minutes per month perpetually; predictable per-minute billing. | Free tier of 10,000 minutes; competitive per-minute rates. | Free tier limited; JaaS pricing oriented toward enterprise. |
| **Privacy & Security** | End-to-end token validation, channel encryption, HIPAA/GDPR compliance certifications. | HIPAA compliant, encrypted in transit. | Encrypted in transit, HIPAA add-on available. |

## Recommendation & Decision
We select **Agora** as the primary hosted video provider for DermaCare, with **Daily.co** as the designated fallback alternative.

## Rationale
1. **South Asian Network Resilience**: Agora's proprietary software-defined real-time network (SD-RTN) provides superior packet loss recovery (up to 70% audio packet loss resilience), vital for patients across varying mobile networks in Nepal.
2. **Flutter Production Readiness**: `agora_rtc_engine` is deeply optimized for mobile devices, including budget Android smartphones widely used in Nepal.
3. **Backend Control**: The Django backend creates appointment-linked channels and signs RTC tokens with timestamp expiration matching the appointment duration (e.g., 20-minute window with grace period). No patient or dermatologist can enter a room without an authentic backend-issued token.
