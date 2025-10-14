import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personel_takip/services/auth_services.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    // Auth state değişikliklerini dinle
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // Auth state değiştiğinde
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    if (user != null) {
      // Kullanıcı giriş yaptıysa, Firestore'dan bilgilerini al
      await _loadUserData(user.uid);
    } else {
      _userModel = null;
    }
    
    notifyListeners();
  }

  // Firestore'dan kullanıcı verilerini yükle
  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _firestoreService.getUser(uid);
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // Kayıt ol
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Firebase Auth'a kayıt
      UserCredential userCredential = await _authService.signUp(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestoreService.createUser(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        role: 'employee', // Varsayılan rol
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Giriş yap
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.signIn(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  // Şifre sıfırlama
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}