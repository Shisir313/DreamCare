"""Permission classes for consent enforcement."""

from rest_framework import exceptions, permissions

from consent.services import check_user_has_current_consent


class HasCurrentConsent(permissions.BasePermission):
    """Allows access only to users who have accepted all current mandatory policies.

    Enforced strictly on clinical, onboarding, and photo upload endpoints.
    """

    message = "You must accept all mandatory active privacy and consent policies before accessing this service."
    code = "consent_required"

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        if check_user_has_current_consent(request.user):
            return True

        raise exceptions.PermissionDenied(detail={"detail": self.message, "code": self.code})
