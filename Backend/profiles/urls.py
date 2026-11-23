"""URL routing for profile endpoints."""

from django.urls import path

from profiles.views import LifestyleProfileView, SkinProfileView

app_name = "profiles"

urlpatterns = [
    path("skin/", SkinProfileView.as_view(), name="skin_profile"),
    path("lifestyle/", LifestyleProfileView.as_view(), name="lifestyle_profile"),
]
