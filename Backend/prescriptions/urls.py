"""URLs for prescriptions, amendments, audits, and weekly check-ins."""

from django.urls import path

from prescriptions.views import (
    AmendPrescriptionView,
    PrescriptionDetailView,
    PrescriptionListCreateView,
    PublishPrescriptionView,
    ReviewCheckInView,
    WeeklyCheckInHistoryView,
    WeeklyCheckInStatusView,
    WeeklyCheckInSubmitView,
)

app_name = "prescriptions"

urlpatterns = [
    # Prescriptions
    path("", PrescriptionListCreateView.as_view(), name="prescription_list_create"),
    path("<uuid:prescription_id>/", PrescriptionDetailView.as_view(), name="prescription_detail"),
    path(
        "<uuid:prescription_id>/publish/",
        PublishPrescriptionView.as_view(),
        name="publish_prescription",
    ),
    path(
        "<uuid:prescription_id>/amend/", AmendPrescriptionView.as_view(), name="amend_prescription"
    ),
    # Check-ins
    path("check-ins/status/", WeeklyCheckInStatusView.as_view(), name="checkin_status"),
    path("check-ins/submit/", WeeklyCheckInSubmitView.as_view(), name="checkin_submit"),
    path("check-ins/history/", WeeklyCheckInHistoryView.as_view(), name="checkin_history"),
    path("check-ins/<uuid:checkin_id>/review/", ReviewCheckInView.as_view(), name="checkin_review"),
]
