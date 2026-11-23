"""Main URL Configuration for DermaCare project."""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

from accounts.views import CurrentUserView, UserDataExportView
from memberships.views import PlanListView
from routines.views import (
    CalculateHydrationGoalView,
    HydrationGoalView,
    LogWaterIntakeView,
    TodayWaterIntakeView,
)

api_v1_patterns = [
    path("", include("core.urls", namespace="core")),
    path("auth/", include("accounts.urls", namespace="accounts")),
    path("consent/", include("consent.urls", namespace="consent")),
    path("profile/", include("profiles.urls", namespace="profiles")),
    path("photos/", include("media_vault.urls", namespace="photos")),
    path("routines/", include("routines.urls", namespace="routines")),
    path("plans/", PlanListView.as_view(), name="plans_direct"),
    path("memberships/", include("memberships.urls", namespace="memberships")),
    path("payments/", include("payments.urls", namespace="payments")),
    path("consultations/", include("consultations.urls", namespace="consultations")),
    path("prescriptions/", include("prescriptions.urls", namespace="prescriptions")),
    path("notifications/", include("notifications.urls", namespace="notifications")),
    # Check-ins shortcuts
    path("check-ins/", include("prescriptions.urls", namespace="checkins")),
    # Hydration direct shortcuts
    path("hydration/goal/", HydrationGoalView.as_view(), name="hydration_goal_direct"),
    path(
        "hydration/goal/calculate/",
        CalculateHydrationGoalView.as_view(),
        name="calculate_hydration_goal_direct",
    ),
    path("hydration/log/", LogWaterIntakeView.as_view(), name="log_water_intake_direct"),
    path("hydration/today/", TodayWaterIntakeView.as_view(), name="today_water_direct"),
    # User shortcuts
    path("me/", CurrentUserView.as_view(), name="me_direct"),
    path("me/export/", UserDataExportView.as_view(), name="me_export_direct"),
]

urlpatterns = [
    path("admin/", admin.site.urls),
    # OpenAPI 3 Schema & Interactive Docs
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
    # API v1 Versioning
    path("api/v1/", include((api_v1_patterns, "api_v1"))),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
