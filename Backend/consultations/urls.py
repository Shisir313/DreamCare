"""URLs for consultations, doctor profiles, availability slots, appointments, and video tokens."""

from django.urls import path

from consultations.views import (
    AppointmentDetailView,
    AppointmentListView,
    AppointmentVideoTokenView,
    BookAppointmentView,
    CancelAppointmentView,
    CreateSlotView,
    DoctorDetailView,
    DoctorListView,
    DoctorSlotsView,
    RescheduleAppointmentView,
)

app_name = "consultations"

urlpatterns = [
    # Doctor profiles & availability slots
    path("doctors/", DoctorListView.as_view(), name="doctor_list"),
    path("doctors/<uuid:doctor_id>/", DoctorDetailView.as_view(), name="doctor_detail"),
    path("doctors/<uuid:doctor_id>/slots/", DoctorSlotsView.as_view(), name="doctor_slots"),
    path("slots/create/", CreateSlotView.as_view(), name="create_slot"),
    # Appointments
    path("book/", BookAppointmentView.as_view(), name="book_appointment"),
    path("appointments/", AppointmentListView.as_view(), name="appointment_list"),
    path(
        "appointments/<uuid:appointment_id>/",
        AppointmentDetailView.as_view(),
        name="appointment_detail",
    ),
    path(
        "appointments/<uuid:appointment_id>/cancel/",
        CancelAppointmentView.as_view(),
        name="cancel_appointment",
    ),
    path(
        "appointments/<uuid:appointment_id>/reschedule/",
        RescheduleAppointmentView.as_view(),
        name="reschedule_appointment",
    ),
    path(
        "appointments/<uuid:appointment_id>/video-token/",
        AppointmentVideoTokenView.as_view(),
        name="appointment_video_token",
    ),
]
