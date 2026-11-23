"""URL routes for consent app."""

from django.urls import path

from consent.views import AcceptConsentView, ConsentStatusView, ListPoliciesView

app_name = "consent"

urlpatterns = [
    path("policies/", ListPoliciesView.as_view(), name="list_policies"),
    path("accept/", AcceptConsentView.as_view(), name="accept_consent"),
    path("status/", ConsentStatusView.as_view(), name="consent_status"),
]
