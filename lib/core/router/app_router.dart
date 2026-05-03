import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/forced_password_change_screen.dart';
import '../../screens/otp_verification_screen.dart';
import '../../screens/totp_verification_screen.dart';
import '../../screens/security_question_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/password_reset_form_screen.dart';
import '../../screens/mfa_setup_screen.dart';
import '../../screens/change_password_screen.dart';
import '../../screens/student_home_screen.dart';
import '../../screens/faculty_home_screen.dart';
import '../../screens/contractor_home_screen.dart';
import '../../screens/alumni_home_screen.dart';
import '../../screens/admin_staff/admin_staff_home_screen.dart';
import '../../screens/it_admin/it_admin_home_screen.dart';
import '../../screens/admin_staff/user_profile_screen.dart';
import '../../screens/admin_staff/edit_user_screen.dart';
import '../../screens/admin_staff/change_status_screen.dart';
import '../../screens/it_admin/user_auth_details_screen.dart';
import '../../core/constants/app_constants.dart';

/// Named route constants.
class AppRoutes {
  AppRoutes._();
  static const String login = '/';
  static const String forgotPassword = '/forgot-password';
  static const String passwordReset = '/password-reset';
  static const String forcedChange = '/forced-change';
  static const String otpVerification = '/otp';
  static const String totpVerification = '/totp';
  static const String securityQuestion = '/security-question';
  static const String mfaSetup = '/mfa-setup';
  static const String changePassword = '/change-password';
  static const String studentHome = '/student';
  static const String facultyHome = '/faculty';
  static const String contractorHome = '/contractor';
  static const String alumniHome = '/alumni';
  static const String adminStaffHome = '/admin-staff';
  static const String itAdminHome = '/it-admin';
  static const String userProfile = '/user-profile/:id';
  static const String editUser = '/edit-user/:id';
  static const String changeStatus = '/change-status/:id';
  static const String userAuthDetails = '/auth-details/:id';
}

/// Creates and provides the GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  final refreshNotifier = _GoRouterRefreshNotifier(authNotifier.stream);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, routerState) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final onAuthPage = routerState.matchedLocation == AppRoutes.login ||
          routerState.matchedLocation == AppRoutes.forgotPassword ||
          routerState.matchedLocation == AppRoutes.passwordReset;

      // If not authenticated and trying to access a protected route → login.
      if (!isAuthenticated &&
          !onAuthPage &&
          routerState.matchedLocation != AppRoutes.otpVerification &&
          routerState.matchedLocation != AppRoutes.totpVerification &&
          routerState.matchedLocation != AppRoutes.securityQuestion &&
          routerState.matchedLocation != AppRoutes.forcedChange &&
          routerState.matchedLocation != AppRoutes.mfaSetup) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (_, state) =>
            PasswordResetFormScreen(personId: state.extra as String),
      ),
      GoRoute(
          path: AppRoutes.forcedChange,
          builder: (_, __) => const ForcedPasswordChangeScreen()),
      GoRoute(
          path: AppRoutes.otpVerification,
          builder: (_, __) => const OtpVerificationScreen()),
      GoRoute(
          path: AppRoutes.totpVerification,
          builder: (_, __) => const TotpVerificationScreen()),
      GoRoute(
          path: AppRoutes.securityQuestion,
          builder: (_, __) => const SecurityQuestionScreen()),
      GoRoute(
          path: AppRoutes.mfaSetup, builder: (_, __) => const MfaSetupScreen()),
      GoRoute(
          path: AppRoutes.changePassword,
          builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(
          path: AppRoutes.studentHome,
          builder: (_, __) => const StudentHomeScreen()),
      GoRoute(
          path: AppRoutes.facultyHome,
          builder: (_, __) => const FacultyHomeScreen()),
      GoRoute(
          path: AppRoutes.contractorHome,
          builder: (_, __) => const ContractorHomeScreen()),
      GoRoute(
          path: AppRoutes.alumniHome,
          builder: (_, __) => const AlumniHomeScreen()),
      GoRoute(
          path: AppRoutes.adminStaffHome,
          builder: (_, __) => const AdminStaffHomeScreen()),
      GoRoute(
          path: AppRoutes.itAdminHome,
          builder: (_, __) => const ItAdminHomeScreen()),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (_, state) =>
            UserProfileScreen(personId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.editUser,
        builder: (_, state) =>
            EditUserScreen(personId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.changeStatus,
        builder: (_, state) =>
            ChangeStatusScreen(personId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.userAuthDetails,
        builder: (_, state) =>
            UserAuthDetailsScreen(personId: state.pathParameters['id']!),
      ),
    ],
  );
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Returns the home route for the given userType.
String homeRouteForType(String userType) {
  switch (userType) {
    case AppConstants.typeUndergraduate:
    case AppConstants.typeContinuingEducation:
    case AppConstants.typePhD:
    case AppConstants.typeInternational:
      return AppRoutes.studentHome;
    case AppConstants.typeTenured:
    case AppConstants.typeAdjunct:
    case AppConstants.typeVisitingResearcher:
      return AppRoutes.facultyHome;
    case AppConstants.typeAdministrativeStaff:
    case AppConstants.typeTechnicalStaff:
    case AppConstants.typeTemporaryStaff:
      return AppRoutes.adminStaffHome;
    case AppConstants.typeITAdmin:
      return AppRoutes.itAdminHome;
    case AppConstants.typeContractor:
      return AppRoutes.contractorHome;
    case AppConstants.typeAlumni:
      return AppRoutes.alumniHome;
    default:
      return AppRoutes.login;
  }
}
