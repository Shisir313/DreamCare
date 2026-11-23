"""Management command to populate database with realistic Nepali dermatology demo data.

Seeds patients (Sujana, Triyog, Rasmi), verified dermatologists with NMC credentials,
availability slots, active memberships, routines, hydration goals, prescriptions, and check-ins.
"""

from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from accounts.models import User, UserRole
from consent.models import ConsentPolicy, ConsentRecord, PolicyType
from consultations.models import (
    Appointment,
    AppointmentStatus,
    AppointmentType,
    AvailabilitySlot,
    DermatologistProfile,
    DermatologistSpecialty,
)
from memberships.models import Membership, MembershipStatus, Plan, PlanCode
from memberships.services import seed_default_plans
from notifications.models import Notification, NotificationType
from prescriptions.models import (
    Prescription,
    WeeklyCheckIn,
    WeeklyCheckInStatus,
)
from profiles.models import (
    LifestyleProfile,
    SkinProfile,
    SkinTone,
    SkinType,
)
from routines.services import (
    calculate_and_set_hydration_goal,
    evaluate_rules_for_user,
    seed_default_recommendation_rules,
)


class Command(BaseCommand):
    help = "Seed realistic Nepal clinical demo data matching product personas and Flutter frontend."

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write("Starting DermaCare Nepal demo database seeding...")

        # 1. Seed Plans & Recommendation Rules
        seed_default_plans()
        seed_default_recommendation_rules()
        self.stdout.write(self.style.SUCCESS("✓ Seeded baseline plans and clinical rules."))

        # 2. Consent Policies
        policies = [
            (
                PolicyType.TERMS_OF_SERVICE,
                "Terms of Service",
                "Platform usage agreement and tele-consultation scope in Nepal.",
            ),
            (
                PolicyType.PRIVACY_POLICY,
                "Privacy Policy",
                "Data protection strictly aligned with Nepal Individual Privacy Act 2018.",
            ),
            (
                PolicyType.HEALTH_DATA_CONSENT,
                "Health Data Consent",
                "Consent for dermatologists to review private face photos and skin logs.",
            ),
            (
                PolicyType.TELEMEDICINE_CONSENT,
                "Telemedicine Consent",
                "Acknowledgment of online consultation advisory scope and limitations.",
            ),
        ]
        created_policies = []
        for p_type, title, summary in policies:
            policy, _ = ConsentPolicy.objects.get_or_create(
                policy_type=p_type,
                version="1.0",
                defaults={
                    "title": title,
                    "summary": summary,
                    "is_mandatory": True,
                    "is_active": True,
                },
            )
            created_policies.append(policy)
        self.stdout.write(self.style.SUCCESS("✓ Seeded active consent policies (v1.0)."))

        # 3. Superuser Admin
        admin_user, _ = User.objects.get_or_create(
            email="admin@dermacare.np",
            defaults={
                "name": "DermaCare Administrator",
                "role": UserRole.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_email_verified": True,
            },
        )
        admin_user.set_password("AdminPassword123!")
        admin_user.save()

        # 4. Verified Dermatologists
        dermatologists_data = [
            {
                "email": "dr.anjali@dermacare.np",
                "name": "Dr. Anjali Sharma",
                "phone": "9841234567",
                "nmc_number": "NMC-12345",
                "specialty": DermatologistSpecialty.DERMATOLOGIST,
                "qualifications": "MBBS, MD (Dermatology)",
                "experience_years": 12,
                "rating": 4.85,
                "total_reviews": 156,
                "consultation_fee_paisa": 150000,
                "hospital": "Nepal Mediciti Hospital",
                "about": "Specialized in acne treatment, skin allergies, and cosmetic dermatology.",
                "languages": ["Nepali", "English", "Hindi"],
            },
            {
                "email": "dr.rajesh@dermacare.np",
                "name": "Dr. Rajesh Thapa",
                "phone": "9851234567",
                "nmc_number": "NMC-15678",
                "specialty": DermatologistSpecialty.DERMATOLOGIST,
                "qualifications": "MBBS, MD (Dermatology), Fellowship (UK)",
                "experience_years": 15,
                "rating": 4.90,
                "total_reviews": 203,
                "consultation_fee_paisa": 200000,
                "hospital": "Grande International Hospital",
                "about": "Expert in complex skin conditions, psoriasis, eczema, and medical dermatology.",
                "languages": ["Nepali", "English"],
            },
            {
                "email": "dr.sushma@dermacare.np",
                "name": "Dr. Sushma Karki",
                "phone": "9861234567",
                "nmc_number": "NMC-18901",
                "specialty": DermatologistSpecialty.COSMETOLOGIST,
                "qualifications": "MBBS, PG Diploma (Aesthetic Medicine)",
                "experience_years": 8,
                "rating": 4.70,
                "total_reviews": 98,
                "consultation_fee_paisa": 120000,
                "hospital": "Skin & Aesthetics Clinic, Lalitpur",
                "about": "Specialized in chemical peels, skin rejuvenation, and barrier restoration.",
                "languages": ["Nepali", "English"],
            },
        ]

        verified_doctors = []
        now = timezone.now()
        for doc in dermatologists_data:
            user, _ = User.objects.get_or_create(
                email=doc["email"],
                defaults={
                    "name": doc["name"],
                    "phone": doc["phone"],
                    "role": UserRole.DERMATOLOGIST,
                    "is_email_verified": True,
                },
            )
            user.set_password("DoctorPassword123!")
            user.save()

            profile, _ = DermatologistProfile.objects.update_or_create(
                user=user,
                defaults={
                    "nmc_number": doc["nmc_number"],
                    "is_verified": True,
                    "specialty": doc["specialty"],
                    "qualifications": doc["qualifications"],
                    "experience_years": doc["experience_years"],
                    "rating": doc["rating"],
                    "total_reviews": doc["total_reviews"],
                    "consultation_fee_paisa": doc["consultation_fee_paisa"],
                    "hospital": doc["hospital"],
                    "about": doc["about"],
                    "languages": doc["languages"],
                },
            )
            verified_doctors.append(profile)

            # Generate availability slots for today, tomorrow, and day after in Asia/Kathmandu
            for day_offset in range(0, 4):
                slot_date = (now + timedelta(days=day_offset)).date()
                for hour in [10, 11, 14, 15]:
                    start_dt = timezone.make_aware(
                        timezone.datetime.combine(
                            slot_date, timezone.datetime.min.time().replace(hour=hour, minute=0)
                        )
                    )
                    end_dt = start_dt + timedelta(minutes=30)
                    AvailabilitySlot.objects.get_or_create(
                        dermatologist=profile,
                        start_time=start_dt,
                        defaults={"end_time": end_dt, "is_booked": False},
                    )

        self.stdout.write(
            self.style.SUCCESS("✓ Seeded 3 verified dermatologists and weekly availability slots.")
        )

        # 5. Seed Patients & Personas
        # Persona 1: Sujana Shrestha (19, Student, Acne/Oily, Basic Plan)
        sujana, _ = User.objects.get_or_create(
            email="sujana@dermacare.np",
            defaults={
                "name": "Sujana Shrestha",
                "phone": "9841000001",
                "role": UserRole.PATIENT,
                "is_email_verified": True,
                "is_onboarded": True,
            },
        )
        sujana.set_password("SujanaPassword123!")
        sujana.save()

        # Consent records
        for p in created_policies:
            ConsentRecord.objects.get_or_create(
                user=sujana,
                policy_type=p.policy_type,
                policy_version="1.0",
                defaults={"ip_hash": "seed_hash", "user_agent_hash": "seed_ua_hash"},
            )

        # Profiles
        SkinProfile.objects.update_or_create(
            user=sujana,
            defaults={
                "skin_type": SkinType.OILY,
                "skin_tone": SkinTone.MEDIUM,
                "conditions": ["acne"],
                "concerns": ["blemishes", "oiliness"],
            },
        )
        LifestyleProfile.objects.update_or_create(
            user=sujana,
            defaults={"height_cm": 158.0, "weight_kg": 52.0, "age": 19},
        )

        # Basic Plan Membership
        basic_plan = Plan.objects.get(code=PlanCode.BASIC)
        sujana_membership, _ = Membership.objects.update_or_create(
            user=sujana,
            defaults={
                "plan": basic_plan,
                "status": MembershipStatus.ACTIVE,
                "start_date": now - timedelta(days=3),
                "end_date": now + timedelta(days=25),
                "consultations_remaining": 0,  # 1 used
                "checkins_remaining": 3,  # 1 used
            },
        )

        # Routine & Hydration
        evaluate_rules_for_user(user=sujana)
        calculate_and_set_hydration_goal(user=sujana)

        # Appointment booked for tomorrow with Dr. Anjali
        anjali_profile = verified_doctors[0]
        tomorrow_slot = AvailabilitySlot.objects.filter(
            dermatologist=anjali_profile,
            start_time__gt=now,
            is_booked=False,
        ).first()

        if tomorrow_slot:
            tomorrow_slot.is_booked = True
            tomorrow_slot.save(update_fields=["is_booked"])
            Appointment.objects.update_or_create(
                patient=sujana,
                slot=tomorrow_slot,
                defaults={
                    "dermatologist": anjali_profile,
                    "status": AppointmentStatus.CONFIRMED,
                    "appointment_type": AppointmentType.VIDEO,
                    "fee_paisa": anjali_profile.consultation_fee_paisa,
                    "symptoms": "Persistent breakouts around cheeks and chin area.",
                    "room_channel": f"dermacare_sujana_{tomorrow_slot.id.hex[:8]}",
                },
            )

        # Active Prescription
        Prescription.objects.update_or_create(
            patient=sujana,
            dermatologist=anjali_profile,
            version=1,
            defaults={
                "diagnosis": "Acne Vulgaris (Grade II - Moderate)",
                "medications": [
                    {
                        "name": "Adapalene Gel 0.1%",
                        "dosage": "Pea-sized amount",
                        "frequency": "Once daily at night",
                        "duration": "8 weeks",
                        "instructions": "Apply to clean, dry skin. Avoid direct sunlight.",
                        "beforeMeal": False,
                    },
                    {
                        "name": "Clindamycin Gel 1%",
                        "dosage": "Thin layer",
                        "frequency": "Twice daily",
                        "duration": "8 weeks",
                        "instructions": "Use morning and evening.",
                        "beforeMeal": False,
                    },
                ],
                "instructions": "Use gentle non-comedogenic cleanser and sunscreen every morning.",
                "notes": "Follow up in 4 weeks to review progress.",
                "follow_up_date": (now + timedelta(days=25)).date(),
                "is_published": True,
                "published_at": now - timedelta(days=2),
            },
        )

        # Week 1 Check-in
        WeeklyCheckIn.objects.update_or_create(
            membership=sujana_membership,
            week_number=1,
            defaults={
                "patient": sujana,
                "patient_note": "Starting the topical gel. Mild dryness noticed around nose.",
                "status": WeeklyCheckInStatus.REVIEWED,
                "dermatologist": anjali_profile,
                "dermatologist_feedback": "Dryness is expected with retinoids. Use hydrating ceramide moisturizer.",
                "reviewed_at": now - timedelta(days=1),
            },
        )

        # Notifications
        Notification.objects.get_or_create(
            user=sujana,
            title="Appointment Reminder",
            defaults={
                "body": "Your video consultation with Dr. Anjali Sharma is tomorrow at 10:00 AM.",
                "notification_type": NotificationType.APPOINTMENT,
                "is_read": False,
            },
        )
        Notification.objects.get_or_create(
            user=sujana,
            title="Hydration Reminder",
            defaults={
                "body": "Time to drink a fresh glass of water. Daily goal: 1,820 mL.",
                "notification_type": NotificationType.HYDRATION,
                "is_read": True,
            },
        )

        # Persona 2: Triyog Bhattarai (28, Professional, Dry/Sensitive, Premium Plan)
        triyog, _ = User.objects.get_or_create(
            email="triyog@dermacare.np",
            defaults={
                "name": "Triyog Bhattarai",
                "phone": "9841000002",
                "role": UserRole.PATIENT,
                "is_email_verified": True,
                "is_onboarded": True,
            },
        )
        triyog.set_password("TriyogPassword123!")
        triyog.save()

        for p in created_policies:
            ConsentRecord.objects.get_or_create(
                user=triyog,
                policy_type=p.policy_type,
                policy_version="1.0",
                defaults={"ip_hash": "seed_hash", "user_agent_hash": "seed_ua_hash"},
            )

        SkinProfile.objects.update_or_create(
            user=triyog,
            defaults={
                "skin_type": SkinType.DRY,
                "skin_tone": SkinTone.MEDIUM,
                "concerns": ["sensitivity", "dryness"],
            },
        )
        LifestyleProfile.objects.update_or_create(
            user=triyog,
            defaults={"height_cm": 175.0, "weight_kg": 70.0, "age": 28},
        )

        premium_plan = Plan.objects.get(code=PlanCode.PREMIUM)
        Membership.objects.update_or_create(
            user=triyog,
            defaults={
                "plan": premium_plan,
                "status": MembershipStatus.ACTIVE,
                "start_date": now,
                "end_date": now + timedelta(days=28),
                "consultations_remaining": 2,
                "checkins_remaining": 4,
            },
        )
        evaluate_rules_for_user(user=triyog)
        calculate_and_set_hydration_goal(user=triyog)

        # Persona 3: Rasmi Sharma (40, Teacher, Pay-per-Consultation)
        rasmi, _ = User.objects.get_or_create(
            email="rasmi@dermacare.np",
            defaults={
                "name": "Rasmi Sharma",
                "phone": "9841000003",
                "role": UserRole.PATIENT,
                "is_email_verified": True,
                "is_onboarded": True,
            },
        )
        rasmi.set_password("RasmiPassword123!")
        rasmi.save()

        for p in created_policies:
            ConsentRecord.objects.get_or_create(
                user=rasmi,
                policy_type=p.policy_type,
                policy_version="1.0",
                defaults={"ip_hash": "seed_hash", "user_agent_hash": "seed_ua_hash"},
            )

        SkinProfile.objects.update_or_create(
            user=rasmi,
            defaults={
                "skin_type": SkinType.NORMAL,
                "skin_tone": SkinTone.DEEP,
                "concerns": ["aging", "pigmentation"],
            },
        )
        LifestyleProfile.objects.update_or_create(
            user=rasmi,
            defaults={"height_cm": 155.0, "weight_kg": 58.0, "age": 40},
        )
        evaluate_rules_for_user(user=rasmi)
        calculate_and_set_hydration_goal(user=rasmi)

        self.stdout.write(
            self.style.SUCCESS("✓ Seeded realistic patient personas (Sujana, Triyog, Rasmi).")
        )
        self.stdout.write(self.style.SUCCESS("DermaCare Nepal demo database seeding complete!"))
