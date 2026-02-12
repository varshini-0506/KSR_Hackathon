import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/splash_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_setup_page.dart';
import '../pages/trusted_circle_page.dart';
import '../pages/home_dashboard.dart';
import '../pages/geofence_view_page.dart';
import '../pages/risk_monitoring_page.dart';
import '../pages/soft_prompt_page.dart';
import '../pages/emergency_escalation_page.dart';
import '../pages/incident_summary_page.dart';
import '../pages/alert_history_page.dart';
import '../pages/guardian_view_page.dart';
import '../pages/privacy_permissions_page.dart';
import '../pages/settings_page.dart';
import '../widgets/main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeDashboard(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => MainScaffold(
        title: 'Profile Setup',
        body: const ProfileSetupPage(),
      ),
    ),
    GoRoute(
      path: '/trusted-circle',
      builder: (context, state) => MainScaffold(
        title: 'Trusted Circle',
        body: const TrustedCirclePage(),
      ),
    ),
    GoRoute(
      path: '/geofence',
      builder: (context, state) => MainScaffold(
        title: 'Geofence View',
        body: const GeofenceViewPage(),
      ),
    ),
    GoRoute(
      path: '/risk-monitoring',
      builder: (context, state) => MainScaffold(
        title: 'Risk Monitoring',
        body: const RiskMonitoringPage(),
      ),
    ),
    GoRoute(
      path: '/soft-prompt',
      builder: (context, state) => const SoftPromptPage(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyEscalationPage(),
    ),
    GoRoute(
      path: '/incident-summary',
      builder: (context, state) => MainScaffold(
        title: 'Incident Summary',
        body: const IncidentSummaryPage(),
      ),
    ),
    GoRoute(
      path: '/alert-history',
      builder: (context, state) => MainScaffold(
        title: 'Alert History',
        body: const AlertHistoryPage(),
      ),
    ),
    GoRoute(
      path: '/guardian-view',
      builder: (context, state) => MainScaffold(
        title: 'Guardian View',
        body: const GuardianViewPage(),
      ),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => MainScaffold(
        title: 'Privacy & Permissions',
        body: const PrivacyPermissionsPage(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => MainScaffold(
        title: 'Settings',
        body: const SettingsPage(),
      ),
    ),
  ],
);
