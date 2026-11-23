"""Tests for consistent exception handler formatting."""

from django.http import Http404
from rest_framework import exceptions, status
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory

from core.exceptions import custom_exception_handler


def test_validation_error_formatting():
    factory = APIRequestFactory()
    request = Request(factory.post("/test/"))
    context = {"request": request}
    exc = exceptions.ValidationError({"email": ["Enter a valid email address."]})

    response = custom_exception_handler(exc, context)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.data
    assert "error" in data
    assert data["error"]["code"] == "validation_error"
    assert "details" in data["error"]
    assert "email" in data["error"]["details"]


def test_not_found_formatting():
    factory = APIRequestFactory()
    request = Request(factory.get("/missing/"))
    context = {"request": request}
    exc = Http404()

    response = custom_exception_handler(exc, context)
    assert response.status_code == status.HTTP_404_NOT_FOUND
    assert response.data["error"]["code"] == "not_found"


def test_permission_denied_formatting():
    factory = APIRequestFactory()
    request = Request(factory.get("/secret/"))
    context = {"request": request}
    exc = exceptions.PermissionDenied()

    response = custom_exception_handler(exc, context)
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert response.data["error"]["code"] == "permission_denied"


def test_unhandled_exception_formatting():
    factory = APIRequestFactory()
    request = Request(factory.get("/crash/"))
    context = {"request": request}
    exc = RuntimeError("Database crashed unexpectedly")

    response = custom_exception_handler(exc, context)
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert response.data["error"]["code"] == "server_error"
    # Ensure raw exception details are NOT leaked to the client
    assert "Database crashed" not in response.data["error"]["message"]
