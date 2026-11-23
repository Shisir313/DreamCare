"""Admin configuration for payment orders, attempts, and audit ledger."""

from django.contrib import admin

from payments.models import PaymentAttempt, PaymentOrder, PaymentStatusHistory


class PaymentAttemptInline(admin.TabularInline):
    model = PaymentAttempt
    extra = 0
    readonly_fields = [
        "gateway",
        "attempt_reference",
        "gateway_transaction_id",
        "status",
        "amount_paisa",
        "created_at",
    ]
    can_delete = False


class PaymentStatusHistoryInline(admin.TabularInline):
    model = PaymentStatusHistory
    extra = 0
    readonly_fields = ["from_status", "to_status", "reason", "created_at"]
    can_delete = False


@admin.register(PaymentOrder)
class PaymentOrderAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user_email",
        "plan_name",
        "amount_npr",
        "status",
        "created_at",
    ]
    list_filter = ["status", "created_at"]
    search_fields = ["id", "user__email", "user__name", "idempotency_key"]
    readonly_fields = ["id", "idempotency_key", "created_at", "updated_at"]
    inlines = [PaymentAttemptInline, PaymentStatusHistoryInline]

    def user_email(self, obj):
        return obj.user.email

    def plan_name(self, obj):
        return obj.plan.name if obj.plan else "-"

    def amount_npr(self, obj):
        return f"Rs {obj.amount_paisa // 100}"


@admin.register(PaymentAttempt)
class PaymentAttemptAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "order_id",
        "gateway",
        "attempt_reference",
        "gateway_transaction_id",
        "status",
        "amount_npr",
        "created_at",
    ]
    list_filter = ["gateway", "status", "created_at"]
    search_fields = [
        "attempt_reference",
        "gateway_transaction_id",
        "order__id",
        "order__user__email",
    ]
    readonly_fields = [
        "order",
        "gateway",
        "attempt_reference",
        "gateway_transaction_id",
        "status",
        "amount_paisa",
        "gateway_response_raw",
        "created_at",
        "updated_at",
    ]

    def order_id(self, obj):
        return obj.order.id

    def amount_npr(self, obj):
        return f"Rs {obj.amount_paisa // 100}"
