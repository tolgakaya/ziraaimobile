import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';
import '../../domain/entities/auth_session.dart';

abstract class AuthLocalDataSource {
  Future<void> storeTokens(AuthTokensModel tokens);
  Future<AuthTokensModel?> getStoredTokens();
  Future<void> removeTokens();

  Future<void> storeUser(UserModel user);
  Future<UserModel?> getStoredUser();
  Future<void> removeUser();

  Future<void> storeSession(AuthSession session);
  Future<AuthSession?> getStoredSession();
  Future<void> removeSession();

  Future<void> storeRememberMe(bool rememberMe);
  Future<bool> getRememberMe();

  Future<void> storeBiometricEnabled(bool enabled);
  Future<bool> getBiometricEnabled();

  Future<void> storeLastLoginEmail(String email);
  Future<String?> getLastLoginEmail();

  Future<void> storeDeviceId(String deviceId);
  Future<String?> getDeviceId();

  Future<void> clearAllAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenTypeKey = 'auth_token_type';
  static const String _expiresAtKey = 'auth_expires_at';
  static const String _scopesKey = 'auth_scopes';

  static const String _userDataKey = 'user_data';
  static const String _sessionDataKey = 'session_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginEmailKey = 'last_login_email';
  static const String _deviceIdKey = 'device_id';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;

  const AuthLocalDataSourceImpl({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences sharedPreferences,
  }) : _secureStorage = secureStorage,
       _sharedPreferences = sharedPreferences;

  @override
  Future<void> storeTokens(AuthTokensModel tokens) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _secureStorage.write(key: _tokenTypeKey, value: tokens.tokenType),
      _secureStorage.write(key: _expiresAtKey, value: tokens.expiresAt.toIso8601String()),
      if (tokens.scopes != null)
        _secureStorage.write(key: _scopesKey, value: jsonEncode(tokens.scopes)),
    ]);
  }

  @override
  Future<AuthTokensModel?> getStoredTokens() async {
    try {
      final results = await Future.wait([
        _secureStorage.read(key: _accessTokenKey),
        _secureStorage.read(key: _refreshTokenKey),
        _secureStorage.read(key: _tokenTypeKey),
        _secureStorage.read(key: _expiresAtKey),
        _secureStorage.read(key: _scopesKey),
      ]);

      final accessToken = results[0];
      final refreshToken = results[1];
      final tokenType = results[2];
      final expiresAtStr = results[3];
      final scopesStr = results[4];

      if (accessToken == null || refreshToken == null || tokenType == null ||
          expiresAtStr == null) {
        return null;
      }

      final expiresAt = DateTime.parse(expiresAtStr);
      final scopes = scopesStr != null ?
          List<String>.from(jsonDecode(scopesStr)) : <String>[];

      return AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
        expiresAt: expiresAt,
        scopes: scopes,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _tokenTypeKey),
      _secureStorage.delete(key: _expiresAtKey),
      _secureStorage.delete(key: _scopesKey),
    ]);
  }

  @override
  Future<void> storeUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _secureStorage.write(key: _userDataKey, value: userJson);
  }

  @override
  Future<UserModel?> getStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userDataKey);
      if (userJson == null) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeUser() async {
    await _secureStorage.delete(key: _userDataKey);
  }

  @override
  Future<void> storeSession(AuthSession session) async {
    final userModel = UserModel.fromDomain(session.user);
    final sessionData = {
      'user': userModel.toJson(),
      'tokens': {
        'accessToken': session.tokens.accessToken,
        'refreshToken': session.tokens.refreshToken,
        'tokenType': session.tokens.tokenType,
        'expiresAt': session.tokens.expiresAt.toIso8601String(),
        'scopes': session.tokens.scopes,
      },
      'deviceId': session.deviceId,
      'loginTime': session.loginTime.toIso8601String(),
      'ipAddress': session.ipAddress,
      'sessionMetadata': session.sessionMetadata,
    };

    final sessionJson = jsonEncode(sessionData);
    await _secureStorage.write(key: _sessionDataKey, value: sessionJson);
  }

  @override
  Future<AuthSession?> getStoredSession() async {
    try {
      final sessionJson = await _secureStorage.read(key: _sessionDataKey);
      if (sessionJson == null) return null;

      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      final userMap = sessionMap['user'] as Map<String, dynamic>;
      final tokensMap = sessionMap['tokens'] as Map<String, dynamic>;

      final user = UserModel.fromJson(userMap).toDomain();
      final tokens = AuthTokensModel(
        accessToken: tokensMap['accessToken'],
        refreshToken: tokensMap['refreshToken'],
        tokenType: tokensMap['tokenType'],
        expiresAt: DateTime.parse(tokensMap['expiresAt']),
        scopes: tokensMap['scopes'] != null ?
            List<String>.from(tokensMap['scopes']) : [],
      ).toDomain();

      return AuthSession(
        user: user,
        tokens: tokens,
        loginTime: DateTime.parse(sessionMap['loginTime']),
        deviceId: sessionMap['deviceId'],
        ipAddress: sessionMap['ipAddress'],
        sessionMetadata: sessionMap['sessionMetadata'] != null ?
            Map<String, dynamic>.from(sessionMap['sessionMetadata']) : null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeSession() async {
    await _secureStorage.delete(key: _sessionDataKey);
  }

  @override
  Future<void> storeRememberMe(bool rememberMe) async {
    await _sharedPreferences.setBool(_rememberMeKey, rememberMe);
  }

  @override
  Future<bool> getRememberMe() async {
    return _sharedPreferences.getBool(_rememberMeKey) ?? false;
  }

  @override
  Future<void> storeBiometricEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_biometricEnabledKey, enabled);
  }

  @override
  Future<bool> getBiometricEnabled() async {
    return _sharedPreferences.getBool(_biometricEnabledKey) ?? false;
  }

  @override
  Future<void> storeLastLoginEmail(String email) async {
    await _sharedPreferences.setString(_lastLoginEmailKey, email);
  }

  @override
  Future<String?> getLastLoginEmail() async {
    return _sharedPreferences.getString(_lastLoginEmailKey);
  }

  @override
  Future<void> storeDeviceId(String deviceId) async {
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
  }

  @override
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  @override
  Future<void> clearAllAuthData() async {
    await Future.wait([
      removeTokens(),
      removeUser(),
      removeSession(),
      _sharedPreferences.remove(_rememberMeKey),
      _sharedPreferences.remove(_biometricEnabledKey),
      _sharedPreferences.remove(_lastLoginEmailKey),
      _secureStorage.delete(key: _deviceIdKey),
    ]);
  }
}