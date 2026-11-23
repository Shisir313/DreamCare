"""Views for managing skin profiles and lifestyle measurements."""

from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from consent.permissions import HasCurrentConsent
from profiles.models import LifestyleProfile, SkinProfile
from profiles.serializers import LifestyleProfileSerializer, SkinProfileSerializer


class SkinProfileView(APIView):
    """Retrieve or update skin profile for current patient."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]
    serializer_class = SkinProfileSerializer

    @extend_schema(
        summary="Get Skin Profile",
        description="Returns skin profile attributes, concerns, and routine level. Requires active consent.",
        responses={200: SkinProfileSerializer},
        tags=["Profiles"],
    )
    def get(self, request):
        profile, _ = SkinProfile.objects.get_or_create(user=request.user)
        serializer = SkinProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Create or Update Skin Profile",
        description="Updates skin type, skin tone, reported conditions, concerns, routine level, and sun exposure.",
        request=SkinProfileSerializer,
        responses={200: SkinProfileSerializer},
        tags=["Profiles"],
    )
    def put(self, request):
        profile, _ = SkinProfile.objects.get_or_create(user=request.user)
        serializer = SkinProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Partially Update Skin Profile",
        description="Partially updates skin profile attributes.",
        request=SkinProfileSerializer,
        responses={200: SkinProfileSerializer},
        tags=["Profiles"],
    )
    def patch(self, request):
        return self.put(request)


class LifestyleProfileView(APIView):
    """Retrieve or update lifestyle attributes and measurements."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]
    serializer_class = LifestyleProfileSerializer

    @extend_schema(
        summary="Get Lifestyle Profile & Measurements",
        description="Returns height, weight, sleep, stress, activity level, and server-side computed BMI.",
        responses={200: LifestyleProfileSerializer},
        tags=["Profiles"],
    )
    def get(self, request):
        profile, _ = LifestyleProfile.objects.get_or_create(user=request.user)
        serializer = LifestyleProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Create or Update Lifestyle Profile",
        description="Updates height, weight, sleep hours, stress level, and activity level. Calculates BMI.",
        request=LifestyleProfileSerializer,
        responses={200: LifestyleProfileSerializer},
        tags=["Profiles"],
    )
    def put(self, request):
        profile, _ = LifestyleProfile.objects.get_or_create(user=request.user)
        serializer = LifestyleProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Partially Update Lifestyle Profile",
        description="Partially updates lifestyle attributes and measurements.",
        request=LifestyleProfileSerializer,
        responses={200: LifestyleProfileSerializer},
        tags=["Profiles"],
    )
    def patch(self, request):
        return self.put(request)
