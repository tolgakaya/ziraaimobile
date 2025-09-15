/// Generic API response wrapper following ZiraAI format
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  String? get errorMessage => message;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'],
      errorCode: json['errorCode'],
    );
  }
}