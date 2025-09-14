import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_tokens.dart';

part 'auth_tokens_model.g.dart';

@JsonSerializable()
class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime expiresAt;
  final List<String> scopes;

  AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresAt,
    this.scopes = const [],
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokensModelToJson(this);

  AuthTokens toDomain() {
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresAt: expiresAt,
      scopes: scopes,
    );
  }

  factory AuthTokensModel.fromDomain(AuthTokens tokens) {
    return AuthTokensModel(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      tokenType: tokens.tokenType,
      expiresAt: tokens.expiresAt,
      scopes: tokens.scopes,
    );
  }

  AuthTokensModel copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    List<String>? scopes,
  }) {
    return AuthTokensModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
      scopes: scopes ?? this.scopes,
    );
  }
}