"""URL routing for memberships and plans."""

from django.urls import path

from memberships.views import (
    CancelMembershipView,
    CurrentMembershipView,
    MembershipHistoryView,
    PlanListView,
    SelectPlanView,
)

app_name = "memberships"

urlpatterns = [
    path("plans/", PlanListView.as_view(), name="plan_list"),
    path("current/", CurrentMembershipView.as_view(), name="current_membership"),
    path("select/", SelectPlanView.as_view(), name="select_plan"),
    path("<uuid:membership_id>/cancel/", CancelMembershipView.as_view(), name="cancel_membership"),
    path("history/", MembershipHistoryView.as_view(), name="membership_history"),
]
