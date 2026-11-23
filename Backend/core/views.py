"""Core views including system health check."""

from django.db import connection
from django.utils import timezone
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import fields, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthCheckView(APIView):
    """System health check endpoint for monitoring, load balancers, and Flutter."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="System Health Check",
        description="Returns system operational status, UTC & Asia/Kathmandu timestamps, and database health.",
        responses={
            200: inline_serializer(
                name="HealthCheckResponse",
                fields={
                    "status": fields.CharField(default="ok"),
                    "environment": fields.CharField(),
                    "timezone": fields.CharField(default="Asia/Kathmandu"),
                    "utc_time": fields.DateTimeField(),
                    "local_time": fields.DateTimeField(),
                    "database": fields.CharField(default="connected"),
                },
            ),
            503: inline_serializer(
                name="HealthCheckErrorResponse",
                fields={
                    "status": fields.CharField(default="unhealthy"),
                    "database": fields.CharField(),
                },
            ),
        },
        tags=["System"],
    )
    def get(self, request):
        db_status = "connected"
        http_status = status.HTTP_200_OK

        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1;")
                cursor.fetchone()
        except Exception as exc:
            db_status = f"disconnected: {str(exc)}"
            http_status = status.HTTP_503_SERVICE_UNAVAILABLE

        now_utc = timezone.now()
        local_time = timezone.localtime(now_utc)

        payload = {
            "status": "ok" if http_status == status.HTTP_200_OK else "unhealthy",
            "timezone": str(timezone.get_current_timezone_name()),
            "utc_time": now_utc.isoformat(),
            "local_time": local_time.isoformat(),
            "database": db_status,
        }

        return Response(payload, status=http_status)
