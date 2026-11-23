"""URL routing for media vault endpoints."""

from django.urls import path

from media_vault.views import (
    PhotoListView,
    PhotoSignedUrlView,
    PhotoUploadView,
    PrivatePhotoStreamView,
)

app_name = "photos"

urlpatterns = [
    path("", PhotoListView.as_view(), name="photo_list"),
    path("upload/", PhotoUploadView.as_view(), name="photo_upload"),
    path("<uuid:photo_id>/url/", PhotoSignedUrlView.as_view(), name="photo_signed_url"),
    path("view/<str:token>/", PrivatePhotoStreamView.as_view(), name="stream_photo"),
]
