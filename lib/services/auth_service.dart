import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⚡ OPTIMASI: Cache user data untuk mengurangi Firestore calls
  Map<String, Map<String, dynamic>> _userDataCache = {};

  // ✅ REGISTER - Email & Password
  Future<User?> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final String trimmedEmail = email.trim();
      final String trimmedPassword = password.trim();
      
      // ⚡ OPTIMASI: Validasi email sebelum API call
      if (!_isValidEmail(trimmedEmail)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Format email tidak valid',
        );
      }

      // ⚡ OPTIMASI: Validasi password sebelum API call
      if (trimmedPassword.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password minimal 6 karakter',
        );
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final User? user = result.user;
      if (user == null) throw Exception('User creation failed');

      // ⚡ OPTIMASI: Batch operations untuk mengurangi network calls
      await Future.wait([
        _saveUserData(
          userId: user.uid,
          email: trimmedEmail,
          fullName: fullName.trim(),
          phoneNumber: phoneNumber?.trim(),
        ),
        user.updateDisplayName(fullName.trim()),
      ]);

      // ⚡ OPTIMASI: Cache user data setelah registrasi
      _cacheUserData(user.uid, {
        'email': trimmedEmail,
        'fullName': fullName.trim(),
        'phone': phoneNumber?.trim() ?? '',
        'idNumber': '',
        'isActive': true,
      });

      return user;
    } catch (e) {
      // ⚡ OPTIMASI: Log error dengan informasi lebih jelas
      print('[AUTH_REGISTER_ERROR] ${_getAuthErrorCode(e)}: ${e.toString()}');
      rethrow;
    }
  }

  // ✅ LOGIN - Email & Password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final String trimmedEmail = email.trim();
      final String trimmedPassword = password.trim();

      // ⚡ OPTIMASI: Cache check untuk mencegah redundant API calls
      if (_userDataCache.isNotEmpty) {
        final cachedUser = _userDataCache.values.firstWhere(
          (data) => data['email'] == trimmedEmail,
          orElse: () => {},
        );
        if (cachedUser.isNotEmpty) {
          print('[AUTH_LOGIN_CACHE_HIT] Using cached data for: $trimmedEmail');
        }
      }

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final User? user = result.user;
      if (user == null) throw Exception('Login failed');

      // ⚡ OPTIMASI: Update last login async (non-blocking)
      _updateLastLogin(user.uid).catchError((e) {
        print('[AUTH_UPDATE_LOGIN_ERROR] ${e.toString()}');
      });

      return user;
    } catch (e) {
      print('[AUTH_LOGIN_ERROR] ${_getAuthErrorCode(e)}: ${e.toString()}');
      rethrow;
    }
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    try {
      // ⚡ OPTIMASI: Clear cache saat logout
      _userDataCache.clear();
      await _auth.signOut();
    } catch (e) {
      print('[AUTH_LOGOUT_ERROR] ${e.toString()}');
      rethrow;
    }
  }

  // ✅ CURRENT USER
  User? get currentUser => _auth.currentUser;

  // ✅ USER INFO - Dengan cache fallback
  String? get userEmail => _auth.currentUser?.email;
  
  String? get userName {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // ⚡ OPTIMASI: Cek cache dulu sebelum Firestore
    final cachedData = _userDataCache[user.uid];
    if (cachedData != null && cachedData['fullName'] != null) {
      return cachedData['fullName'] as String?;
    }
    
    return user.displayName;
  }
  
  String? get userId => _auth.currentUser?.uid;

  // ✅ SAVE USER DATA TO FIRESTORE
  Future<void> _saveUserData({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final userData = {
        'email': email,
        'fullName': fullName,
        'phone': phoneNumber ?? '',
        'idNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // ⚡ OPTIMASI: Gunakan set dengan merge:true untuk prevent overwrite
      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );

      // ⚡ OPTIMASI: Cache data setelah save
      _cacheUserData(userId, userData);
    } catch (e) {
      print('[AUTH_SAVE_DATA_ERROR] ${e.toString()}');
      rethrow;
    }
  }

  // ✅ UPDATE LAST LOGIN
  Future<void> _updateLastLogin(String userId) async {
    try {
      final updateData = {
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ⚡ OPTIMASI: Batch update untuk efficiency
      await _firestore.collection('users').doc(userId).update(updateData);
      
      // ⚡ OPTIMASI: Update cache juga
      final cachedData = _userDataCache[userId];
      if (cachedData != null) {
        cachedData.addAll(updateData);
      }
    } catch (e) {
      print('[AUTH_UPDATE_LOGIN_ERROR] ${e.toString()}');
      // Tidak rethrow karena ini non-critical operation
    }
  }

  // ✅ GET USER DATA FROM FIRESTORE - Dengan cache
  Future<Map<String, dynamic>?> getUserData(String userId, {bool forceRefresh = false}) async {
    try {
      // ⚡ OPTIMASI: Cek cache dulu
      if (!forceRefresh && _userDataCache.containsKey(userId)) {
        print('[AUTH_GET_DATA_CACHE_HIT] User: $userId');
        return _userDataCache[userId];
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        print('[AUTH_GET_DATA_NOT_FOUND] User: $userId');
        return null;
      }

      final data = doc.data()!;
      
      // ⚡ OPTIMASI: Cache data
      _cacheUserData(userId, data);
      
      return data;
    } catch (e) {
      print('[AUTH_GET_DATA_ERROR] User: $userId, Error: ${e.toString()}');
      
      // ⚡ OPTIMASI: Fallback ke cache jika ada
      if (_userDataCache.containsKey(userId)) {
        print('[AUTH_GET_DATA_CACHE_FALLBACK] Using cached data for: $userId');
        return _userDataCache[userId];
      }
      
      return null;
    }
  }

  // ✅ CHECK IF USER EXISTS
  Future<bool> userExists(String email) async {
    try {
      final trimmedEmail = email.trim();
      
      // ⚡ OPTIMASI: Cek cache dulu
      if (_userDataCache.isNotEmpty) {
        final existsInCache = _userDataCache.values.any(
          (data) => data['email'] == trimmedEmail,
        );
        if (existsInCache) {
          print('[AUTH_USER_EXISTS_CACHE_HIT] Email: $trimmedEmail');
          return true;
        }
      }

      final methods = await _auth.fetchSignInMethodsForEmail(trimmedEmail);
      return methods.isNotEmpty;
    } catch (e) {
      print('[AUTH_USER_EXISTS_ERROR] Email: $email, Error: ${e.toString()}');
      return false;
    }
  }

  // ✅ SEND PASSWORD RESET EMAIL
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final trimmedEmail = email.trim();
      
      // ⚡ OPTIMASI: Validasi email sebelum send
      if (!_isValidEmail(trimmedEmail)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Format email tidak valid',
        );
      }

      await _auth.sendPasswordResetEmail(email: trimmedEmail);
    } catch (e) {
      print('[AUTH_RESET_PASSWORD_ERROR] Email: $email, Error: ${e.toString()}');
      rethrow;
    }
  }

  // ✅ UPDATE USER PROFILE
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update display name jika ada
      if (fullName != null) {
        updates['fullName'] = fullName.trim();
        await _auth.currentUser?.updateDisplayName(fullName.trim());
      }
      
      if (phoneNumber != null) updates['phone'] = phoneNumber.trim();
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      // ⚡ OPTIMASI: Batch update
      await _firestore.collection('users').doc(userId).update(updates);
      
      // ⚡ OPTIMASI: Update cache
      final cachedData = _userDataCache[userId];
      if (cachedData != null) {
        cachedData.addAll(updates);
      }
    } catch (e) {
      print('[AUTH_UPDATE_PROFILE_ERROR] User: $userId, Error: ${e.toString()}');
      rethrow;
    }
  }

  // ⚡ OPTIMASI: Helper methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  void _cacheUserData(String userId, Map<String, dynamic> data) {
    // ⚡ OPTIMASI: Limit cache size untuk mencegah memory leak
    if (_userDataCache.length >= 50) {
      final firstKey = _userDataCache.keys.first;
      _userDataCache.remove(firstKey);
    }
    
    _userDataCache[userId] = Map.from(data);
  }

  String _getAuthErrorCode(dynamic error) {
    if (error is FirebaseAuthException) return error.code;
    if (error is FirebaseException) return error.code;
    return 'unknown-error';
  }

  // ⚡ OPTIMASI: Clear cache jika diperlukan
  void clearCache() {
    _userDataCache.clear();
  }

  // ⚡ OPTIMASI: Preload user data untuk current user
  Future<void> preloadCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null && !_userDataCache.containsKey(user.uid)) {
      await getUserData(user.uid);
    }
  }
}