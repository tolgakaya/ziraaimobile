import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final NetworkClient _networkClient;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(
    this._networkClient,
    this._secureStorage,
  );

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);
      
      final response = await _networkClient.dio.post(
        '${ApiConfig.apiBaseUrl}${ApiConfig.login}',
        data: request.toJson(),
      );

      print('API Response: ${response.data}');
      print('API Response Type: ${response.data.runtimeType}');

      // Handle different response types from login API
      if (response.data is String) {
        // API returns string for errors or simple success
        final stringResponse = response.data as String;
        print('Login string response: $stringResponse');

        // Check if it's a success response (might be JSON string)
        try {
          // Try to parse as JSON if it looks like JSON
          if (stringResponse.startsWith('{') && stringResponse.endsWith('}')) {
            final Map<String, dynamic> jsonData = jsonDecode(stringResponse);
            final loginResponse = LoginResponse.fromJson(jsonData);

            if (loginResponse.success && loginResponse.data != null) {
              // Store token and process success
              await _secureStorage.write(
                key: 'auth_token',
                value: loginResponse.data!.token,
              );

              if (loginResponse.data!.refreshToken != null) {
                await _secureStorage.write(
                  key: 'refresh_token',
                  value: loginResponse.data!.refreshToken!,
                );
              }

              // Create UserEntity - if user data is not available, create a minimal one
              final user = loginResponse.data!.user != null 
                ? UserEntity(
                    id: loginResponse.data!.user!.id,
                    email: loginResponse.data!.user!.email,
                    firstName: loginResponse.data!.user!.firstName,
                    lastName: loginResponse.data!.user!.lastName,
                    role: loginResponse.data!.user!.role,
                    phoneNumber: loginResponse.data!.user!.phoneNumber,
                    isEmailVerified: loginResponse.data!.user!.emailVerified ?? false,
                    tier: loginResponse.data!.user!.tier,
                  )
                : UserEntity(
                    id: 'unknown',
                    email: email, // Use login email
                    firstName: 'User',
                    lastName: '',
                    role: 'Farmer',
                    phoneNumber: null,
                    isEmailVerified: false,
                    tier: null,
                  );

              return Right(user);
            }
          }
        } catch (e) {
          print('JSON parse failed: $e');
        }

        // If we reach here, it's likely an error string
        return Left(ServerFailure(message: stringResponse));
      } else {
        // Handle JSON response normally
        final loginResponse = LoginResponse.fromJson(response.data);

        if (loginResponse.success && loginResponse.data != null) {
          // Store token
          await _secureStorage.write(
            key: 'auth_token',
            value: loginResponse.data!.token,
          );

          // Store refresh token if available
          if (loginResponse.data!.refreshToken != null) {
            await _secureStorage.write(
              key: 'refresh_token',
              value: loginResponse.data!.refreshToken!,
            );
          }

          // Create UserEntity - if user data is not available, create a minimal one
          final user = loginResponse.data!.user != null 
            ? UserEntity(
                id: loginResponse.data!.user!.id,
                email: loginResponse.data!.user!.email,
                firstName: loginResponse.data!.user!.firstName,
                lastName: loginResponse.data!.user!.lastName,
                role: loginResponse.data!.user!.role,
                phoneNumber: loginResponse.data!.user!.phoneNumber,
                isEmailVerified: loginResponse.data!.user!.emailVerified ?? false,
                tier: loginResponse.data!.user!.tier,
              )
            : UserEntity(
                id: 'unknown',
                email: email, // Use login email
                firstName: 'User',
                lastName: '',
                role: 'Farmer',
                phoneNumber: null,
                isEmailVerified: false,
                tier: null,
              );

          return Right(user);
        } else {
          return Left(ServerFailure(
            message: loginResponse.message ?? 'Login failed',
          ));
        }
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null) {
        final errorData = e.response!.data;

        // API string hata mesajlarını yakala
        if (errorData is String) {
          String errorMessage;
          if (errorData.isEmpty) {
            // Boş string durumu - büyük ihtimalle bağlantı problemi
            errorMessage = 'Bağlantı hatası - Lütfen tekrar deneyin';
          } else {
            switch (errorData.trim()) {
              case 'PasswordError':
                errorMessage = 'Şifre hatalı';
                break;
              case 'UserNotFound':
                errorMessage = 'Kullanıcı bulunamadı';
                break;
              default:
                errorMessage = errorData;
            }
          }
          return Left(ServerFailure(message: errorMessage));
        } else if (errorData is Map) {
          final errorMessage = errorData['message'] ?? 'Login failed';
          return Left(ServerFailure(message: errorMessage));
        } else {
          return Left(ServerFailure(message: 'Login failed'));
        }
      } else {
        return const Left(NetworkFailure());
      }
    } catch (e) {
      print('Unexpected error: $e');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
  }) async {
    try {
      // Validate passwords match
      if (password != confirmPassword) {
        return const Left(ValidationFailure(
          message: 'Passwords do not match',
        ));
      }

      // Default to Farmer role for now
      final request = RegisterRequest(
        email: email,
        password: password,
        fullName: '$firstName $lastName',
        mobilePhones: phoneNumber,
        role: 'Farmer',
      );

      print('*** Register Request ***');
      print('uri: ${ApiConfig.apiBaseUrl}${ApiConfig.register}');
      print('data: ${request.toJson()}');

      // Create a separate Dio instance for register to avoid interceptor issues
      final registerDio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ));

      final response = await registerDio.post(
        ApiConfig.register,
        data: request.toJson(),
        options: Options(
          responseType: ResponseType.plain, // Raw string response
        ),
      );

      print('Register API Response: ${response.data}');
      print('Register Response Type: ${response.data.runtimeType}');
      print('Register Status Code: ${response.statusCode}');

      // Success for any 2xx status code with plain text response
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        print('Register success (status: ${response.statusCode}) - attempting login');
        // After successful registration, attempt to login
        return login(email: email, password: password);
      } else {
        return Left(ServerFailure(message: 'Registration failed with status: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('Register DioException Details:');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('Error: ${e.error}');

      // Eğer FormatException ise ve API'den cevap gelirse, başarılı kabul et
      if (e.error is FormatException && e.response != null && e.response!.statusCode == 200) {
        print('Register succeeded but got FormatException - treating as success');
        return login(email: email, password: password);
      }
      if (e.response != null) {
        final errorData = e.response!.data;
        final statusCode = e.response!.statusCode;

        print('API Error - Status: $statusCode, Data: $errorData');

        // Handle server errors
        if (statusCode == 500) {
          String errorMessage = 'Sunucu hatası - Lütfen daha sonra tekrar deneyin';
          if (errorData is String && errorData.contains('Something went wrong')) {
            errorMessage = 'Kayıt sırasında bir hata oluştu - Lütfen tekrar deneyin';
          }
          return Left(ServerFailure(message: errorMessage));
        }

        // API string hata mesajlarını yakala
        if (errorData is String) {
          String errorMessage;
          if (errorData.isEmpty) {
            errorMessage = 'Kayıt hatası - Lütfen tekrar deneyin';
          } else {
            switch (errorData.trim()) {
              case 'EmailAlreadyExists':
                errorMessage = 'Bu email adresi zaten kullanımda';
                break;
              case 'ValidationError':
                errorMessage = 'Girilen bilgiler geçersiz';
                break;
              case 'WeakPassword':
                errorMessage = 'Şifre çok zayıf';
                break;
              case 'Something went wrong. Please try again.':
                errorMessage = 'Kayıt sırasında bir hata oluştu - Lütfen tekrar deneyin';
                break;
              default:
                errorMessage = errorData;
            }
          }
          return Left(ServerFailure(message: errorMessage));
        } else if (errorData is Map) {
          final errorMessage = errorData['message'] ?? 'Registration failed';
          return Left(ServerFailure(message: errorMessage));
        } else {
          return Left(ServerFailure(message: 'Registration failed'));
        }
      } else {
        print('No response from server - likely network connection issue');
        return Left(ServerFailure(message: 'Bağlantı hatası - İnternet bağlantınızı kontrol edin'));
      }
    } on FormatException catch (e) {
      print('Register FormatException (likely string response): $e');
      // Eğer format exception ise, muhtemelen string response gelmiş
      // Successful registration olarak kabul edebiliriz
      return login(email: email, password: password);
    } catch (e) {
      print('Register unexpected error: $e');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Clear stored tokens
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'refresh_token');
      
      // Clear network client auth header
      _networkClient.dio.options.headers.remove('Authorization');
      
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      return Right(token != null && token.isNotEmpty);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        return const Left(UnauthorizedFailure());
      }

      final response = await _networkClient.dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.userProfile}',
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final userData = response.data['data'];
        
        final user = UserEntity(
          id: userData['id'],
          email: userData['email'],
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          role: userData['role'],
          phoneNumber: userData['phoneNumber'],
          isEmailVerified: userData['emailVerified'] ?? false,
          tier: userData['tier'],
        );

        return Right(user);
      } else {
        return const Left(ServerFailure(message: 'Failed to get user profile'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}