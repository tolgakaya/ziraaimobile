enum SecurityLevel {
  low,
  standard,
  high,
  maximum
}

extension SecurityLevelExtension on SecurityLevel {
  int get level {
    switch (this) {
      case SecurityLevel.low:
        return 1;
      case SecurityLevel.standard:
        return 2;
      case SecurityLevel.high:
        return 3;
      case SecurityLevel.maximum:
        return 4;
    }
  }

  Duration get autoLogoutDuration {
    switch (this) {
      case SecurityLevel.low:
        return const Duration(hours: 24);
      case SecurityLevel.standard:
        return const Duration(hours: 4);
      case SecurityLevel.high:
        return const Duration(hours: 1);
      case SecurityLevel.maximum:
        return const Duration(minutes: 30);
    }
  }

  bool get requiresBiometric {
    switch (this) {
      case SecurityLevel.low:
        return false;
      case SecurityLevel.standard:
        return false;
      case SecurityLevel.high:
        return true;
      case SecurityLevel.maximum:
        return true;
    }
  }
}