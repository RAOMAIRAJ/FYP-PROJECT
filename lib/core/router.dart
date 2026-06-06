import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/presentation/screens/splash_screen.dart';
import 'package:qanoon_buddy/presentation/screens/auth/login_screen.dart';
import 'package:qanoon_buddy/presentation/screens/home/home_screen.dart';
import 'package:qanoon_buddy/presentation/screens/auth/lawyer_register_screen.dart';
import 'package:qanoon_buddy/presentation/screens/forgot_password_screen.dart';
import 'package:qanoon_buddy/presentation/screens/reset_password_screen.dart';
import 'package:qanoon_buddy/presentation/screens/ai_tools_screen.dart';
import 'package:qanoon_buddy/presentation/screens/analyze_document_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/risk_analyzer_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/fir_generator_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/bail_calculator_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/lawyer_match_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/emergency_helplines_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/citizen_services_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/case_tracker_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/legal_form_builder_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/legal_directory_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/appointment_booking_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/digital_legal_wallet_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/my_vehicles_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/challan_verification_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/complaint_generator_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/department_guide_screen.dart';
import 'package:qanoon_buddy/presentation/screens/karachi/karachi_live_map_screen.dart';
import 'package:qanoon_buddy/presentation/screens/karachi/ai_route_advisor_screen.dart';
import 'package:qanoon_buddy/presentation/screens/karachi/smart_govt_office_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/cplc_recovery_screen.dart';
import 'package:qanoon_buddy/presentation/screens/admin/radar_admin_screen.dart';
import 'package:qanoon_buddy/presentation/screens/citizen_app/citizen_app_dashboard.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lawyer-register',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LawyerRegisterScreen(initialData: extra);
        },
      ),
      GoRoute(
  path: '/forgot-password',
  builder: (_, __) => const ForgotPasswordScreen(),
),
GoRoute(
  path: '/reset-password',
  builder: (context, state) => ResetPasswordScreen(
    token: state.uri.queryParameters['token'] ?? '',
  ),
),
      GoRoute(
        path: '/ai-tools',
        builder: (context, state) => const AiToolsScreen(),
      ),
      GoRoute(
        path: '/analyze-document',
        builder: (context, state) => const AnalyzeDocumentScreen(),
      ),
      GoRoute(
        path: '/risk-analyzer',
        builder: (context, state) => const RiskAnalyzerScreen(),
      ),
      GoRoute(
        path: '/fir-generator',
        builder: (context, state) => const FirGeneratorScreen(),
      ),
      GoRoute(
        path: '/bail-calculator',
        builder: (context, state) => const BailCalculatorScreen(),
      ),
      GoRoute(
        path: '/lawyer-match',
        builder: (context, state) => const LawyerMatchScreen(),
      ),
      GoRoute(
        path: '/emergency-helplines',
        builder: (context, state) => const EmergencyHelplinesScreen(),
      ),
      GoRoute(
        path: '/citizen-services',
        builder: (context, state) => const CitizenServicesScreen(),
      ),
      GoRoute(
        path: '/citizen-services/challan',
        builder: (context, state) => const ChallanVerificationScreen(),
      ),
      GoRoute(
        path: '/case-tracker',
        builder: (context, state) => const CaseTrackerScreen(),
      ),
      GoRoute(
        path: '/form-builder',
        builder: (context, state) => const LegalFormBuilderScreen(),
      ),
      GoRoute(
        path: '/legal-directory',
        builder: (context, state) => const LegalDirectoryScreen(),
      ),
      GoRoute(
        path: '/form-booking',
        builder: (context, state) {
          final lawyerName = state.extra as String?;
          return AppointmentBookingScreen(initialLawyerName: lawyerName);
        },
      ),
      GoRoute(
        path: '/digital-wallet',
        builder: (context, state) => const DigitalLegalWalletScreen(),
      ),
      GoRoute(
        path: '/my-vehicles',
        builder: (context, state) => const MyVehiclesScreen(),
      ),
      GoRoute(
        path: '/complaint-generator',
        builder: (context, state) => const ComplaintGeneratorScreen(),
      ),
      GoRoute(
        path: '/department-guide',
        builder: (context, state) => const DepartmentGuideScreen(),
      ),
      GoRoute(
        path: '/karachi-live-map',
        builder: (context, state) => const KarachiLiveMapScreen(),
      ),
      GoRoute(
        path: '/ai-route-advisor',
        builder: (context, state) => const AiRouteAdvisorScreen(),
      ),
      GoRoute(
        path: '/smart-govt-office',
        builder: (context, state) => const SmartGovtOfficeScreen(),
      ),
      GoRoute(
        path: '/cplc-recovery',
        builder: (context, state) => const CplcRecoveryScreen(),
      ),
      GoRoute(
        path: '/radar-admin',
        builder: (context, state) => const RadarAdminScreen(),
      ),
      GoRoute(
        path: '/citizen-mini-app',
        builder: (context, state) => const CitizenAppDashboard(),
      ),
    ],
  );
});

