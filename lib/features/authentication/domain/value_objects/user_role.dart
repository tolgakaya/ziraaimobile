/// User roles in the ZiraAI system with permission levels.
/// Supports the three main roles: Farmer, Sponsor, and Admin.
enum UserRole {
  farmer('farmer'),
  sponsor('sponsor'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  /// Returns the display name for the role
  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.sponsor:
        return 'Sponsor';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Returns the role description
  String get description {
    switch (this) {
      case UserRole.farmer:
        return 'Agricultural professional using plant analysis services';
      case UserRole.sponsor:
        return 'Agricultural company providing sponsored plant analysis services';
      case UserRole.admin:
        return 'System administrator with full access rights';
    }
  }

  /// Returns the permission level (higher = more permissions)
  int get permissionLevel {
    switch (this) {
      case UserRole.farmer:
        return 1;
      case UserRole.sponsor:
        return 2;
      case UserRole.admin:
        return 3;
    }
  }

  /// Returns whether this role can access admin features
  bool get canAccessAdmin => this == UserRole.admin;

  /// Returns whether this role can manage sponsors
  bool get canManageSponsors => this == UserRole.admin;

  /// Returns whether this role can create sponsorship links
  bool get canCreateSponsorshipLinks => 
      this == UserRole.sponsor || this == UserRole.admin;

  /// Returns whether this role can perform plant analysis
  bool get canPerformPlantAnalysis => true; // All roles can analyze plants

  /// Returns whether this role can access analytics
  bool get canAccessAnalytics => 
      this == UserRole.sponsor || this == UserRole.admin;

  /// Returns whether this role can manage farmers
  bool get canManageFarmers => this == UserRole.admin;

  /// Returns whether this role has elevated privileges
  bool get hasElevatedPrivileges => 
      this == UserRole.sponsor || this == UserRole.admin;

  /// Creates a UserRole from a string value
  static UserRole? fromString(String? value) {
    if (value == null) return null;
    
    for (final role in UserRole.values) {
      if (role.value.toLowerCase() == value.toLowerCase()) {
        return role;
      }
    }
    return null;
  }

  /// Returns a list of all available roles for display
  static List<UserRole> get allRoles => UserRole.values;

  /// Returns a list of roles that can be assigned by the current role
  List<UserRole> getAssignableRoles() {
    switch (this) {
      case UserRole.admin:
        return [UserRole.farmer, UserRole.sponsor]; // Admin can assign farmer/sponsor
      case UserRole.sponsor:
        return []; // Sponsors cannot assign roles
      case UserRole.farmer:
        return []; // Farmers cannot assign roles
    }
  }

  @override
  String toString() => value;
}