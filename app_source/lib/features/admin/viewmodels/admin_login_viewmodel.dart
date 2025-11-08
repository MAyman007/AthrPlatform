import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/services/firebase_service.dart';

class AdminLoginViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService = locator<AdminApiService>();
  final FirebaseService _firebaseService = locator<FirebaseService>();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First, check if the email is an authorized admin
      final isAdmin = await _adminApiService.isAdmin(email);

      if (!isAdmin) {
        _errorMessage = 'This email is not an authorized admin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // If admin, proceed with Firebase authentication
      await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;

      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many login attempts. Please try again later.';
          break;
        default:
          _errorMessage = 'Authentication failed: ${e.message}';
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
