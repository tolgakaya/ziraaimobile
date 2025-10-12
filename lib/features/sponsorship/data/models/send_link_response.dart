class SendLinkResponse {
  final bool success;
  final String message;
  final SendLinkData? data;

  SendLinkResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SendLinkResponse.fromJson(Map<String, dynamic> json) {
    return SendLinkResponse(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? SendLinkData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SendLinkData {
  final int totalSent;
  final int successCount;
  final int failureCount;
  final List<SendLinkResult> results;

  SendLinkData({
    required this.totalSent,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  factory SendLinkData.fromJson(Map<String, dynamic> json) {
    return SendLinkData(
      totalSent: json['totalSent'] as int,
      successCount: json['successCount'] as int,
      failureCount: json['failureCount'] as int,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => SendLinkResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SendLinkResult {
  final String code;
  final String phone;
  final bool success;
  final String? errorMessage;
  final String deliveryStatus;

  SendLinkResult({
    required this.code,
    required this.phone,
    required this.success,
    this.errorMessage,
    required this.deliveryStatus,
  });

  factory SendLinkResult.fromJson(Map<String, dynamic> json) {
    return SendLinkResult(
      code: json['code'] as String,
      phone: json['phone'] as String,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      deliveryStatus: json['deliveryStatus'] as String? ?? 'Unknown',
    );
  }
}
