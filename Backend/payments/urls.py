"""URL routing for payments."""

from django.urls import path

from payments.views import (
    CreateOrderView,
    GatewayWebhookView,
    InitiateCheckoutView,
    OrderDetailView,
    VerifyPaymentView,
)

app_name = "payments"

urlpatterns = [
    path("orders/create/", CreateOrderView.as_view(), name="create_order"),
    path("orders/<uuid:order_id>/", OrderDetailView.as_view(), name="order_detail"),
    path("checkout/initiate/", InitiateCheckoutView.as_view(), name="initiate_checkout"),
    path("verify/", VerifyPaymentView.as_view(), name="verify_payment"),
    path("webhook/<str:gateway>/", GatewayWebhookView.as_view(), name="gateway_webhook"),
]
