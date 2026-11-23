"""Tests for versioned rule engine, routines, task toggles, hydration, and reminders."""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from consent.models import ConsentPolicy, ConsentRecord
from consent.services import initialize_default_policies
from profiles.models import SkinProfile, SkinType
from routines.models import UserRoutine
from routines.services import get_local_kathmandu_date, seed_default_recommendation_rules

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def patient_user(db):
    user = User.objects.create_user(
        email="sujana@example.com",
        password="Password123!",
        name="Sujana",
        phone="9801234567",
    )
    initialize_default_policies()
    seed_default_recommendation_rules()

    for p in ConsentPolicy.objects.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="test_ip",
            user_agent_hash="test_ua",
        )
    return user


@pytest.mark.django_db
def test_rule_engine_matches_sujana_persona(api_client, patient_user):
    api_client.force_authenticate(user=patient_user)

    # Set Sujana's profile: oily, acne
    SkinProfile.objects.create(
        user=patient_user,
        skin_type=SkinType.OILY,
        concerns=["acne", "oiliness", "largePores"],
    )

    generate_url = reverse("api_v1:routines:generate_routine")
    response = api_client.post(generate_url)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()

    # Verify advisory notes and disclaimer explicitly note pending dermatologist review
    assert "pending dermatologist review" in data["disclaimer"].lower()

    tasks = data["tasks"]
    assert len(tasks) >= 4
    step_names = [t["step_name"] for t in tasks]
    assert "Cleanser" in step_names
    assert "Sunscreen" in step_names

    # Check instructions disclaimer
    for t in tasks:
        assert "pending dermatologist review" in t["instructions"].lower()


@pytest.mark.django_db
def test_task_toggle_check_off_and_uncheck(api_client, patient_user):
    api_client.force_authenticate(user=patient_user)
    SkinProfile.objects.create(user=patient_user, skin_type=SkinType.COMBINATION)

    # Generate routine
    api_client.post(reverse("api_v1:routines:generate_routine"))
    routine = UserRoutine.objects.get(user=patient_user, is_active=True)
    first_task = routine.tasks.first()

    toggle_url = reverse("api_v1:routines:toggle_task", kwargs={"task_id": first_task.id})

    # 1. Toggle ON
    resp1 = api_client.post(toggle_url)
    assert resp1.status_code == status.HTTP_200_OK
    assert resp1.json()["is_completed"] is True
    assert resp1.json()["date"] == get_local_kathmandu_date().isoformat()

    # 2. Toggle OFF
    resp2 = api_client.post(toggle_url)
    assert resp2.status_code == status.HTTP_200_OK
    assert resp2.json()["is_completed"] is False


@pytest.mark.django_db
def test_hydration_formula_and_daily_logging(api_client, patient_user):
    api_client.force_authenticate(user=patient_user)

    # Calculate goal for 60kg patient
    calc_url = reverse("api_v1:calculate_hydration_goal_direct")
    calc_resp = api_client.post(calc_url, {"weight_kg": 60.0}, format="json")
    assert calc_resp.status_code == status.HTTP_200_OK
    goal_data = calc_resp.json()
    # 60 * 35 = 2100 mL -> ceil(2100 / 250) = 9 glasses
    assert goal_data["daily_goal_ml"] == 2100
    assert goal_data["daily_goal_glasses"] == 9
    assert "EFSA" in goal_data["formula_citation"]
    assert "Individual fluid requirements vary" in goal_data["limitations_disclaimer"]

    # Log 2 glasses
    log_url = reverse("api_v1:log_water_intake_direct")
    log_resp = api_client.post(log_url, {"glasses": 2}, format="json")
    assert log_resp.status_code == status.HTTP_201_CREATED

    # Verify Today's Water Tracking (Flutter model compatibility)
    today_url = reverse("api_v1:today_water_direct")
    today_resp = api_client.get(today_url)
    assert today_resp.status_code == status.HTTP_200_OK
    today_data = today_resp.json()
    assert today_data["glassesCompleted"] == 2
    assert today_data["dailyGoal"] == 9
    assert len(today_data["timestamps"]) == 1


@pytest.mark.django_db
def test_daily_summary_aggregation(api_client, patient_user):
    api_client.force_authenticate(user=patient_user)
    SkinProfile.objects.create(user=patient_user, skin_type=SkinType.OILY)

    # 1. Generate routine
    api_client.post(reverse("api_v1:routines:generate_routine"))
    routine = UserRoutine.objects.get(user=patient_user, is_active=True)
    task = routine.tasks.first()

    # 2. Complete 1 task
    api_client.post(reverse("api_v1:routines:toggle_task", kwargs={"task_id": task.id}))

    # 3. Log 3 glasses
    api_client.post(reverse("api_v1:log_water_intake_direct"), {"glasses": 3}, format="json")

    # 4. Fetch daily summary
    summary_url = reverse("api_v1:routines:daily_summary")
    summary_resp = api_client.get(summary_url)
    assert summary_resp.status_code == status.HTTP_200_OK
    data = summary_resp.json()

    assert data["timezone"] == "Asia/Kathmandu"
    assert data["routine"]["completed_tasks"] == 1
    assert data["hydration"]["glassesCompleted"] == 3


@pytest.mark.django_db
def test_reminder_preferences(api_client, patient_user):
    api_client.force_authenticate(user=patient_user)
    reminders_url = reverse("api_v1:routines:reminder_preferences")

    put_resp = api_client.put(
        reminders_url,
        {
            "morning_routine_time": "07:30:00",
            "evening_routine_time": "22:00:00",
            "water_reminders_enabled": True,
            "water_interval_hours": 3,
        },
        format="json",
    )
    assert put_resp.status_code == status.HTTP_200_OK
    assert put_resp.json()["morning_routine_time"] == "07:30:00"
    assert put_resp.json()["water_interval_hours"] == 3
