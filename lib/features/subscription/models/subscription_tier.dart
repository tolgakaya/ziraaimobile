import 'package:flutter/material.dart';

/// Subscription tier model for different plan levels
class SubscriptionTier {
  final int id;
  final String name;
  final String description;
  final double price;
  final int dailyAnalysisLimit;
  final int monthlyAnalysisLimit;
  final List<String> features;
  final bool isRecommended;
  final int durationDays;
  
  SubscriptionTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.dailyAnalysisLimit,
    required this.monthlyAnalysisLimit,
    required this.features,
    this.isRecommended = false,
    this.durationDays = 30,
  });
  
  factory SubscriptionTier.fromJson(Map<String, dynamic> json) {
    return SubscriptionTier(
      id: json['id'] ?? 0,
      name: json['tierName'] ?? json['displayName'] ?? '',
      description: json['description'] ?? '',
      price: (json['monthlyPrice'] ?? 0.0).toDouble(),
      dailyAnalysisLimit: json['dailyRequestLimit'] ?? 0,
      monthlyAnalysisLimit: json['monthlyRequestLimit'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isRecommended: json['isRecommended'] ?? false,
      durationDays: json['durationDays'] ?? 30,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'dailyAnalysisLimit': dailyAnalysisLimit,
      'monthlyAnalysisLimit': monthlyAnalysisLimit,
      'features': features,
      'isRecommended': isRecommended,
      'durationDays': durationDays,
    };
  }
  
  /// Get tier level for comparison
  TierLevel get level {
    switch (name.toLowerCase()) {
      case 'temel':
      case 'basic':
        return TierLevel.basic;
      case 'premium':
        return TierLevel.premium;
      case 'pro':
        return TierLevel.pro;
      case 'enterprise':
        return TierLevel.enterprise;
      default:
        return TierLevel.basic;
    }
  }
  
  /// Get tier color for UI
  Color get color {
    switch (level) {
      case TierLevel.basic:
        return const Color(0xFF81C784); // Light Green
      case TierLevel.premium:
        return const Color(0xFF42A5F5); // Blue
      case TierLevel.pro:
        return const Color(0xFFFF7043); // Orange
      case TierLevel.enterprise:
        return const Color(0xFF8E24AA); // Purple
    }
  }
  
  /// Get display price with currency
  String get displayPrice {
    return '₺${price.toStringAsFixed(0)}/ay';
  }
  
  /// Get total price with tax
  double get priceWithTax {
    return price * 1.20; // 20% KDV
  }
  
  /// Check if tier has feature
  bool hasFeature(String feature) {
    return features.any((f) => f.toLowerCase().contains(feature.toLowerCase()));
  }
  
  @override
  String toString() {
    return 'SubscriptionTier(id: $id, name: $name, price: $price)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionTier && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Tier levels for comparison and sorting
enum TierLevel {
  basic,
  premium,
  pro,
  enterprise,
}

extension TierLevelExtension on TierLevel {
  String get displayName {
    switch (this) {
      case TierLevel.basic:
        return 'Temel';
      case TierLevel.premium:
        return 'Premium';
      case TierLevel.pro:
        return 'Pro';
      case TierLevel.enterprise:
        return 'Enterprise';
    }
  }
  
  int get sortOrder {
    switch (this) {
      case TierLevel.basic:
        return 1;
      case TierLevel.premium:
        return 2;
      case TierLevel.pro:
        return 3;
      case TierLevel.enterprise:
        return 4;
    }
  }
}