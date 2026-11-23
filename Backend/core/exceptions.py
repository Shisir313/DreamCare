"""Consistent exception handling for DermaCare DRF APIs."""

import logging

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.http import Http404
from rest_framework import exceptions, status
from rest_framework.response import Response
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """Transform DRF and standard exceptions into a consistent machine-readable error format.

    Format:
    {
        "error": {
            "code": "machine_readable_code",
            "message": "Human-readable summary",
            "details": {...} | [...] | null
        }
    }
    """
    # Let DRF handle standard DRF exceptions
    response = exception_handler(exc, context)

    # Convert native Django Http404 and PermissionDenied if not already caught
    if response is None:
        if isinstance(exc, Http404):
            response = Response(
                {"detail": "Not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        elif isinstance(exc, DjangoPermissionDenied):
            response = Response(
                {"detail": "Permission denied."},
                status=status.HTTP_403_FORBIDDEN,
            )
        else:
            # Unhandled server exception: Log securely without leaking sensitive info
            logger.exception("Unhandled server exception: %s", exc)
            return Response(
                {
                    "error": {
                        "code": "server_error",
                        "message": "An unexpected error occurred. Please try again later.",
                        "details": None,
                    }
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    code = "error"
    message = "An error occurred."
    details = None

    if isinstance(exc, exceptions.ValidationError):
        code = "validation_error"
        message = "Validation failed for the submitted data."
        details = response.data
    elif isinstance(exc, (exceptions.AuthenticationFailed, exceptions.NotAuthenticated)):
        code = "authentication_failed"
        message = "Authentication credentials were not provided or are invalid."
        details = response.data if isinstance(response.data, dict) else None
    elif isinstance(exc, exceptions.PermissionDenied):
        code = "permission_denied"
        message = "You do not have permission to perform this action."
        details = None
    elif isinstance(exc, (exceptions.NotFound, Http404)):
        code = "not_found"
        message = "The requested resource was not found."
        details = None
    elif isinstance(exc, exceptions.MethodNotAllowed):
        code = "method_not_allowed"
        message = f"Method {context.get('request').method} not allowed."
        details = None
    elif isinstance(exc, exceptions.Throttled):
        code = "throttled"
        wait = getattr(exc, "wait", None)
        message = (
            f"Request was throttled. Expected available in {wait} seconds."
            if wait
            else "Request was throttled."
        )
        details = {"available_in_seconds": wait} if wait else None
    elif isinstance(exc, exceptions.APIException):
        code = getattr(exc, "default_code", "api_error")
        message = str(exc.detail) if hasattr(exc, "detail") else "API error."
        details = response.data if isinstance(response.data, (dict, list)) else None

    # Normalise details if it's just {"detail": "..."}
    if isinstance(details, dict) and "detail" in details and len(details) == 1:
        message = str(details["detail"])
        details = None

    response.data = {
        "error": {
            "code": code,
            "message": message,
            "details": details,
        }
    }

    return response
