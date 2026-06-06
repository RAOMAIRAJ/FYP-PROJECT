import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/notification_service.dart';

const _storage  = FlutterSecureStorage();
const _tokenKey = 'auth_token';

// ── Auth State ────────────────────────────────────────────────

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  bool get isLoggedIn => token != null;

  String? get role => user?['role'] as String?;
  String? get userId => user?['id'] as String?;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AuthState(
      token:         token         ?? this.token,
      user:          user          ?? this.user,
      isLoading:     isLoading     ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error:         error,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadFromStorage();
    return const AuthState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        state = state.copyWith(token: token);
        final user = await apiService.getMe(token);
        state = state.copyWith(user: user, isInitialized: true);
        NotificationService.registerDevice(token);
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (_) {
      await _storage.delete(key: _tokenKey);
      state = state.copyWith(token: null, user: null, isInitialized: true);
    }
  }

  Future<bool> updateRadarArea(String? area) async {
    final token = state.token;
    if (token == null) return false;
    
    try {
      await apiService.updateRadarAlertArea(token, area);
      if (state.user != null) {
        final updatedUser = Map<String, dynamic>.from(state.user!);
        updatedUser['radar_alert_area'] = area;
        state = state.copyWith(user: updatedUser);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginWithFirebaseToken(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fcmToken = await NotificationService().getFCMToken();
      final data = await apiService.socialLogin(
        idToken: idToken,
        fcmToken: fcmToken,
      );
      final token = data['access_token'];
      final user  = data['user'];
      await _storage.write(key: _tokenKey, value: token);
      state = state.copyWith(token: token, user: user, isLoading: false);
      NotificationService.registerDevice(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        return await loginWithFirebaseToken(idToken);
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Google Sign-in failed: $e");
      return false;
    }
  }

  /// Initiates Phone Verification.
  /// Note: The actual verification (OTP entry) happens in the UI.
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null) {
            await loginWithFirebaseToken(idToken);
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          state = state.copyWith(isLoading: false);
          onError(e.message ?? "Phone verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(isLoading: false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      onError(e.toString());
    }
  }

  Future<bool> verifyPhoneOtp(String verificationId, String smsCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        return await loginWithFirebaseToken(idToken);
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "OTP verification failed: $e");
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fcmToken = await NotificationService().getFCMToken();
      final data = await apiService.register(
        fullName: fullName,
        email:    email,
        password: password,
        city:     city,
        fcmToken: fcmToken,
      );
      final token = data['access_token'];
      final user  = data['user'];
      await _storage.write(key: _tokenKey, value: token);
      state = state.copyWith(token: token, user: user, isLoading: false);
      NotificationService.registerDevice(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fcmToken = await NotificationService().getFCMToken();
      final data = await apiService.login(
        email:    email, 
        password: password,
        fcmToken: fcmToken,
      );
      final token = data['access_token'];
      final user  = data['user'];
      await _storage.write(key: _tokenKey, value: token);
      state = state.copyWith(token: token, user: user, isLoading: false);
      NotificationService.registerDevice(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    final token = state.token;
    await _storage.delete(key: _tokenKey);
    state = const AuthState();
    if (token != null) {
      try {
        apiService.clearFcmToken(token).catchError((e) => print("Logout sync error: $e"));
      } catch (_) {}
    }
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.sendOtp(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.verifyOtp(email, otp);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid or expired verification code.');
      return false;
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) return data['detail'].toString();
    }
    final msg = e.toString();
    if (msg.contains('409')) return 'Account already exists.';
    if (msg.contains('401')) return 'Incorrect credentials.';
    return 'Error: $msg';
  }
}

// ── Provider ──────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);