"""Views for photo upload, listing, signed URL generation, and secure streaming."""

from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import FileResponse, Http404
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from consent.permissions import HasCurrentConsent
from media_vault.models import FacePhoto
from media_vault.serializers import (
    FacePhotoResponseSerializer,
    FacePhotoUploadSerializer,
    SignedUrlResponseSerializer,
)
from media_vault.services import (
    create_face_photo,
    generate_signed_photo_url,
    verify_signed_photo_token,
)


class PhotoUploadView(APIView):
    """Upload and sanitize face photo (front, left, right). Requires active consent."""

    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Upload Face Photo",
        description="Uploads a face photo (angle: front, left, right). Strips EXIF metadata, stores in private vault.",
        request=FacePhotoUploadSerializer,
        responses={201: FacePhotoResponseSerializer},
        tags=["Photos"],
    )
    def post(self, request):
        serializer = FacePhotoUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            photo = create_face_photo(
                user=request.user,
                uploaded_file=serializer.validated_data["file"],
                angle=serializer.validated_data["angle"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(
            FacePhotoResponseSerializer(photo, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class PhotoListView(APIView):
    """List current user's active face photos with signed URLs."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="List Face Photos",
        description="Returns all active face photos for current user with short-lived signed URLs.",
        responses={200: FacePhotoResponseSerializer(many=True)},
        tags=["Photos"],
    )
    def get(self, request):
        photos = FacePhoto.objects.filter(user=request.user, is_active=True)
        serializer = FacePhotoResponseSerializer(photos, many=True, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)


class PhotoSignedUrlView(APIView):
    """Generate a fresh short-lived signed URL for a specific photo (audited)."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Get Photo Signed URL",
        description="Generates an audited 15-minute cryptographically signed URL to view a photo.",
        responses={200: SignedUrlResponseSerializer},
        tags=["Photos"],
    )
    def get(self, request, photo_id):
        try:
            photo = FacePhoto.objects.get(id=photo_id, is_active=True)
        except FacePhoto.DoesNotExist as exc:
            raise Http404("Photo not found.") from exc

        # Object-level permission: owner or dermatologist or staff
        if photo.user != request.user and not (
            request.user.is_dermatologist or request.user.is_staff
        ):
            raise PermissionDenied("You do not have permission to view this photograph.")

        signed_url = generate_signed_photo_url(
            photo,
            actor=request.user,
            request=request,
            purpose="url_generation",
        )

        return Response(
            {
                "photo_id": photo.id,
                "signed_url": signed_url,
                "expires_in_seconds": 900,
            },
            status=status.HTTP_200_OK,
        )


class PrivatePhotoStreamView(APIView):
    """Serve private photo binary given valid signed token."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Stream Private Photo",
        description="Validates signed token and streams photo binary. Never caches on public CDNs.",
        responses={(200, "image/jpeg"): bytes},
        tags=["Photos"],
    )
    def get(self, request, token):
        try:
            photo = verify_signed_photo_token(token)
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        response = FileResponse(photo.image_file.open("rb"), content_type=photo.content_type)
        response["Cache-Control"] = "private, no-cache, no-store, must-revalidate"
        response["Pragma"] = "no-cache"
        response["Expires"] = "0"
        return response
