class TenantApiConfig {
  TenantApiConfig({String schoolId = ''}) : schoolId = schoolId.trim();

  String schoolId;

  Map<String, String> headers({
    String? token,
    bool includeContentType = true,
  }) => {
    if (includeContentType) 'Content-Type': 'application/json',
    if (schoolId.isNotEmpty) 'X-School-ID': schoolId,
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}