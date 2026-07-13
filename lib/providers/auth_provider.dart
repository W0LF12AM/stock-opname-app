import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  
  String? _username;
  String? _fullName;
  String? _role;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get role => _role;
  int? get userId => _userId;

  AuthProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _isAuthenticated = true;
      _username = prefs.getString('username');
      _fullName = prefs.getString('full_name');
      _role = prefs.getString('role');
      _userId = prefs.getInt('user_id');
      notifyListeners();
    }
  }

  Future<void> login(String usernameInput, String passwordInput, bool isOnline) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        // Online login
        final userData = await APIService().login(usernameInput, passwordInput);
        _isAuthenticated = true;
        _username = userData['user']['username'];
        _fullName = userData['user']['full_name'];
        _role = userData['user']['role'];
        // 'id' bisa datang sebagai String atau int dari server PHP
        final rawId = userData['user']['id'];
        _userId = rawId is int ? rawId : int.tryParse(rawId.toString());
      } else {
        // Offline login
        final prefs = await SharedPreferences.getInstance();
        final cachedUsername = prefs.getString('username');
        final cachedPassword = prefs.getString('password_hash'); // saved password

        if (cachedUsername == null || cachedPassword == null) {
          throw Exception('Koneksi internet diperlukan untuk login pertama kali.');
        }

        if (cachedUsername.toLowerCase().trim() == usernameInput.toLowerCase().trim() && 
            cachedPassword == passwordInput) {
          _isAuthenticated = true;
          _username = prefs.getString('username');
          _fullName = prefs.getString('full_name');
          _role = prefs.getString('role');
          _userId = prefs.getInt('user_id');
        } else {
          throw Exception('Kredensial offline tidak cocok.');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved session data

    APIService().clearToken(); // Clear token in memory
    _isAuthenticated = false;
    _username = null;
    _fullName = null;
    _role = null;
    _userId = null;
    
    _isLoading = false;
    notifyListeners();
  }
}
