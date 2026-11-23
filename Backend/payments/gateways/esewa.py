"""eSewa ePay v2 Gateway Adapter adhering to official developer specifications."""

import base64
import hashlib
import hmac
import json
import logging
import urllib.parse
import urllib.request
from typing import Any

from django.conf import settings

from payments.gateways.base import BasePaymentGateway, PaymentVerificationResult

logger = logging.getLogger(__name__)


class EsewaGatewayAdapter(BasePaymentGateway):
    """Adapter for eSewa ePay v2 sandbox and production API."""

    def __init__(self):
        # Defaults to official eSewa test merchant credentials
        self.product_code = getattr(settings, "ESEWA_PRODUCT_CODE", "EPAYTEST")
        self.secret_key = getattr(settings, "ESEWA_SECRET_KEY", "8gBm/:&EnhH.1/q")
        self.is_production = getattr(settings, "ESEWA_IS_PRODUCTION", False)

        if self.is_production:
            self.action_url = "https://epay.esewa.com.np/api/epay/main/v2/form"
            self.status_url = "https://epay.esewa.com.np/api/epay/transaction/status/"
        else:
            self.action_url = "https://rc.esewa.com.np/api/epay/main/v2/form"
            self.status_url = "https://rc.esewa.com.np/api/epay/transaction/status/"

    @staticmethod
    def generate_signature(
        secret_key: str, total_amount: str, transaction_uuid: str, product_code: str
    ) -> str:
        """Generate official Base64 HMAC-SHA256 signature for eSewa v2."""
        message = f"total_amount={total_amount},transaction_uuid={transaction_uuid},product_code={product_code}"
        digest = hmac.new(
            secret_key.encode("utf-8"),
            message.encode("utf-8"),
            hashlib.sha256,
        ).digest()
        return base64.b64encode(digest).decode("utf-8")

    def initiate_payment(self, attempt, return_url: str) -> dict[str, Any]:
        """Generate form submission dictionary with signed signature."""
        amount_npr_str = (
            f"{attempt.amount_paisa / 100.0:.2f}".rstrip("0").rstrip(".")
            if (attempt.amount_paisa % 100 == 0)
            else f"{attempt.amount_paisa / 100.0:.2f}"
        )
        if "." not in amount_npr_str and (attempt.amount_paisa % 100 != 0):
            amount_npr_str = f"{attempt.amount_paisa / 100.0:.2f}"

        # Exact total_amount integer or float string
        total_amount = (
            str(int(attempt.amount_paisa / 100))
            if (attempt.amount_paisa % 100 == 0)
            else f"{attempt.amount_paisa / 100:.2f}"
        )

        signature = self.generate_signature(
            secret_key=self.secret_key,
            total_amount=total_amount,
            transaction_uuid=attempt.attempt_reference,
            product_code=self.product_code,
        )

        form_fields = {
            "amount": total_amount,
            "tax_amount": "0",
            "total_amount": total_amount,
            "transaction_uuid": attempt.attempt_reference,
            "product_code": self.product_code,
            "product_service_charge": "0",
            "product_delivery_charge": "0",
            "success_url": return_url,
            "failure_url": return_url,
            "signed_field_names": "total_amount,transaction_uuid,product_code",
            "signature": signature,
        }

        return {
            "gateway": "esewa",
            "action_url": self.action_url,
            "form_fields": form_fields,
            "transaction_uuid": attempt.attempt_reference,
            "amount_npr": attempt.amount_paisa / 100.0,
        }

    def verify_payment(
        self, attempt, callback_payload: dict[str, Any] | None = None
    ) -> PaymentVerificationResult:
        """Direct server-to-server query against eSewa status API."""
        total_amount = (
            str(int(attempt.amount_paisa / 100))
            if (attempt.amount_paisa % 100 == 0)
            else f"{attempt.amount_paisa / 100:.2f}"
        )
        params = {
            "product_code": self.product_code,
            "total_amount": total_amount,
            "transaction_uuid": attempt.attempt_reference,
        }
        query_string = urllib.parse.urlencode(params)
        request_url = f"{self.status_url}?{query_string}"

        req = urllib.request.Request(
            request_url,
            headers={"User-Agent": "DermaCare-Nepal/1.0"},
            method="GET",
        )

        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                raw_data = response.read().decode("utf-8")
                data = json.loads(raw_data)
        except Exception as exc:
            logger.error("eSewa status lookup failed: %s", exc)
            return PaymentVerificationResult(
                is_successful=False,
                amount_paisa=attempt.amount_paisa,
                error_message=f"eSewa server verification failed: {str(exc)}",
            )

        status_val = data.get("status")
        # eSewa returns "COMPLETE" on success
        if status_val == "COMPLETE":
            ref_id = data.get("ref_id")
            # Verify amount consistency
            verified_amount = float(data.get("total_amount", 0.0))
            verified_paisa = int(round(verified_amount * 100))

            if verified_paisa != attempt.amount_paisa:
                return PaymentVerificationResult(
                    is_successful=False,
                    amount_paisa=verified_paisa,
                    raw_response=data,
                    error_message=f"Amount mismatch: Expected {attempt.amount_paisa} paisa, received {verified_paisa} paisa.",
                )

            return PaymentVerificationResult(
                is_successful=True,
                amount_paisa=verified_paisa,
                gateway_transaction_id=str(ref_id),
                raw_response=data,
            )

        return PaymentVerificationResult(
            is_successful=False,
            amount_paisa=attempt.amount_paisa,
            raw_response=data,
            error_message=f"Payment status is {status_val}",
        )
