class UserProfile {
  final int userId;
  final int? partnerId;
  final String name;
  final String username;
  final String email;

  UserProfile({
    required this.userId,
    this.partnerId,
    required this.name,
    required this.username,
    required this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int,
      partnerId: json['partner_id'] as int?,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class AuthResult {
  final String accessToken;
  final String tokenType;
  final UserProfile user;

  AuthResult({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
