"""Base interface for Nepal payment gateways (eSewa & Khalti)."""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any


@dataclass
class PaymentVerificationResult:
    """Standardized result returned by gateway server-to-server verification."""

    is_successful: bool
    amount_paisa: int
    gateway_transaction_id: str | None = None
    raw_response: dict[str, Any] | None = None
    error_message: str | None = None


class BasePaymentGateway(ABC):
    """Abstract interface all Nepal gateway adapters must adhere to."""

    @abstractmethod
    def initiate_payment(self, attempt, return_url: str) -> dict[str, Any]:
        """Generate checkout payload, signature, or payment URL."""
        pass

    @abstractmethod
    def verify_payment(
        self, attempt, callback_payload: dict[str, Any] | None = None
    ) -> PaymentVerificationResult:
        """Perform server-to-server verification check against official gateway status API."""
        pass
